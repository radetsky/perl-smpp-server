#===============================================================================
#
#         FILE:  SMSTradeInDB.pm
#
#  DESCRIPTION:  SMPPServer plugin. Inserts received SMS via SMPP to database.
#             :  Body text converted to URLEncoded UTF-8 charset.
#             :  Latin1 will be just urlencoded
#             :  Binary will be just urlencoded
#
#        NOTES:  ---
#       AUTHOR:  Alex Radetsky (Rad), <rad@rad.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  24.08.10 17:14:18 EEST
#  LAST MODIFY:  27.12.10 around 15:10
#===============================================================================

=head1 NAME

NetSDS::App::SMSTradeInDB

=head1 SYNOPSIS

	use NetSDS::;

=head1 DESCRIPTION

C<NetSDS> SMPPServer plugin. Inserts received SMS via SMPP to database.
Body text converted to URLEncoded UTF-8 charset.

=cut

package NetSDS::App::SMSTradeInDB;

use 5.8.0;
use strict;
use warnings;

use Data::Dumper;

use NetSDS::Util::Convert;
use NetSDS::Util::String;

use base qw(NetSDS::Class::Abstract);

use constant MYSQL_DSN    => 'DBI:mysql:database=mydb;host=192.168.1.53';
use constant MYSQL_USER   => 'netstyle';
use constant MYSQL_SECRET => '';
use constant MYSQL_TABLE  => 'smppd_messages';

use version; our $VERSION = "0.02";
our @EXPORT_OK = qw();

#===============================================================================
#

=head1 CLASS METHODS

=over

=item B<new([...])> - class constructor

    my $object = NetSDS::SomeClass->new(%options);

=cut

#-----------------------------------------------------------------------
sub new {

	my ( $class, $conf ) = @_;

	my $this = $class->SUPER::new();

	$this->{conf} = $conf;
	$this->_connect_db();

	return $this;

}

#***********************************************************************

=head1 OBJECT METHODS

=over

=item B<run(...)> - object method

=cut

#-----------------------------------------------------------------------
#__PACKAGE__->mk_accessors(qw/msgdbh/);
#__PACKAGE__->mk_accessors(qw/msgsth/);

=item B<_put_mt> 

 Inserts into messages table MT message 

=cut 

sub _put_mt {

	my ( $this, $mt ) = @_;

	$mt = $this->_validate_mt($mt);
	$mt = $this->_convert_mt($mt);

	my $rv; 

	eval { 
	$rv = $this->{'msgsth'}->execute(
		$mt->{'msg_type'},
		$mt->{'esme_id'},
		$mt->{'src_addr'},
		$mt->{'dst_addr'},
		$mt->{'body'},
		$mt->{'coding'},
		$mt->{'udh'},
		$mt->{'mwi'},
		$mt->{'mclass'},
		$mt->{'message_id'},
		$mt->{'validity'},
		$mt->{'dereffed'},
		$mt->{'registered_delivery'},
		$mt->{'service_type'},
		$mt->{'extra'},
		$mt->{'received'},
		); 
	}; 

	if  ($@ ) {
		# try to reconnect and once again
		$this->_connect_db();
		$rv = $this->{'msgsth'}->execute(
			$mt->{'msg_type'},
			$mt->{'esme_id'},
			$mt->{'src_addr'},
			$mt->{'dst_addr'},
			$mt->{'body'},
			$mt->{'coding'},
			$mt->{'udh'},
			$mt->{'mwi'},
			$mt->{'mclass'},
			$mt->{'message_id'},
			$mt->{'validity'},
			$mt->{'dereffed'},
			$mt->{'registered_delivery'},
			$mt->{'service_type'},
			$mt->{'extra'},
			$mt->{'received'},
		);
		unless ( defined($rv) ) { return undef; }
	} ## end unless ( defined($rv) )
	return 1;

} ## end sub _put_mt

=item B<_validate_mt> 

  Validate MT and fill empty fields. 

=cut 

sub _validate_mt {

	my ( $this, $mt ) = @_;

	$mt->{'msg_type'} = "MT";
	unless ( defined( $mt->{'esme_id'} ) ) {
		$mt->{'esme_id'} = 0;    # WRONG! Error happens if we use this code.
	}

	return $mt;
}

=item B<_convert2utf8> 
 
   Converts message body from GSM0338 or UCS2-BE to UTF-8 URL Encoded string 
   Binary just urlencoded. 
   Latin1 URLencoded too.

=cut 

sub _convert_mt {

	my ( $this, $msg ) = @_;

	my $str           = $msg->{'body'};
	my $coding        = $msg->{'coding'};
	my $dststr        = $str;
	my @smpp_encoding = ( 'gsm0338', 'binary', 'ucs2-be', 'latin1' );

	if ( defined( $this->{conf}->{'mt'}->{'body_translate'} ) ) {
		# Body translate config found.
		if ( defined( $this->{conf}->{'mt'}->{'body_translate'}->{$coding} ) ) {
			$dststr = str_recode(
				$str,
				$smpp_encoding[$coding],
				$this->{conf}->{'mt'}->{'body_translate'}->{$coding}
			);
		}
	} else {
		# Do it by default

		if ( $coding == 0 ) {
			$dststr = str_recode( $str, 'gsm0338', 'utf8' );
		}
		if ( $coding == 2 ) {
			$dststr = str_recode( $str, 'ucs2-be', 'UTF-16BE' );
		}
	}

	# URLEncode if we need.

	if ( defined( $this->{conf}->{'mt'}->{'body_translate'}->{'urlencode'} ) ) {
		if ( $this->{conf}->{'mt'}->{'body_translate'}->{'urlencode'} =~ /yes/i ) {
			$dststr = conv_str_uri($dststr);
		}
	}

	$msg->{'body'} = $dststr;
	return $msg;

} ## end sub _convert_mt

sub _connect_db {

	my ( $this, @params ) = @_;

	my $dsn    = MYSQL_DSN;
	my $user   = MYSQL_USER;
	my $passwd = MYSQL_SECRET;
	my $table  = MYSQL_TABLE;

	if ( defined( $this->{conf}->{'in_queue'}->{'dsn'} ) ) {
		$dsn    = $this->{conf}->{'in_queue'}->{'dsn'};
		$user   = $this->{conf}->{'in_queue'}->{'db-user'};
		$passwd = $this->{conf}->{'in_queue'}->{'db-password'};
		$table  = $this->{conf}->{'in_queue'}->{'table'};
	}

	# If DBMS isn' t accessible - try reconnect
	unless ( defined( $this->{'msgdbh'} ) ) {
		$this->{'msgdbh'} = DBI->connect_cached( $dsn, $user, $passwd, { RaiseError => 1 }  );
		unless ( defined( $this->{'msgdbh'} ) ) {
			die "Can't connect to $dsn.\n";
		}
	}
	unless ( $this->{'msgdbh'}->ping ) {
		$this->{'msgdbh'} = DBI->connect_cached( $dsn, $user, $passwd, { RaiseError => 1 } );
	}

  if ( defined ( $this->{conf}->{'in_queue'}->{'mysql-set-names'} ) ) { 
	  my $q = 'set names ' . $this->{conf}->{'in_queue'}->{'mysql-set-names'}; 
		$this->{'msgdbh'}->do ($q); 
  }
	
	my $sql = "insert into " . $table . " ( msg_type, esme_id, src_addr, dst_addr, body, coding, udh, mwi, mclass, message_id, validity, deferred, registered_delivery, service_type, extra, received ) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,? ) ";
	$this->{'msgsth'} = $this->{'msgdbh'}->prepare_cached($sql);
	return 1;

} ## end sub _connect_db

sub _disconnect_db { 
	my $this = shift; 

	$this->{'msgdbh'}->disconnect; 
	$this->{'msgdbh'} = undef; 

	return 1; 

}

1;

__END__

=back

=head1 EXAMPLES


=head1 BUGS

Unknown yet

=head1 SEE ALSO

None

=head1 TODO

None

=head1 AUTHOR

Alex Radetsky <rad@rad.kiev.ua>

=cut


