#===============================================================================
#
#         FILE:  SMSTradeInQ.pm
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

NetSDS::App::SMSTradeInQ

=head1 SYNOPSIS

	use NetSDS::;

=head1 DESCRIPTION

C<NetSDS> SMPPServer plugin. Inserts received SMS via SMPP to database.
Body text converted to URLEncoded UTF-8 charset.

=cut

package NetSDS::App::SMSTradeInQ;

use 5.8.0;
use strict;
use warnings;

use IO::Handle;
use IO::Socket qw(:DEFAULT :crlf);

use Time::HiRes qw(usleep);
use Data::Dumper;

use NetSDS::Util::Convert;
use NetSDS::Util::String;

use JSON;

use base qw(NetSDS::App);

use constant MTQ_SOCK => "127.0.0.1:9998";    # From Database to SMPPD

use constant MYSQL_DSN    => 'DBI:mysql:database=mydb1;host=192.168.1.53';
use constant MYSQL_USER   => 'netstyle';
use constant MYSQL_SECRET => '';
use constant MYSQL_TABLE  => 'smppd_messages';

use version; our $VERSION = "0.01";
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

	my ( $class, %params ) = @_;

	my $this = $class->SUPER::new();

	close STDIN;
	close STDOUT;

	return $this;

}

#***********************************************************************

=head1 OBJECT METHODS

=over

=item B<run(...)> - object method

=cut

#-----------------------------------------------------------------------
__PACKAGE__->mk_accessors(qw/msgdbh/);
__PACKAGE__->mk_accessors(qw/msgsth/);

sub run {

	my ( $this, %params ) = @_;

	$this->_connect_db;

	my $mtq_socket = IO::Socket::INET->new(
		LocalAddr => MTQ_SOCK,
		Type      => SOCK_STREAM,
		Listen    => 1,
		ReuseAddr => 1,
		Proto     => 'tcp',
	);

	unless ( defined($mtq_socket) ) {
		$this->speak("[$$] SMSTradeInQ Create socket error : $!");
		die;
	}

	$mtq_socket->autoflush(1);

	# Waiting for every JSON-encoded line.
	while (1) {
		next unless my $connected = $mtq_socket->accept;
		$this->speak("[$$] SMSTradeInQ Something connected.");
		$this->log( "info", "SMSTradeInQ accept connect." );

		while (1) {
			my $recv_buf = $connected->getline;
			chomp $recv_buf;

			my $mt  = from_json( conv_base64_str($recv_buf), { utf8 => 1 } );
			my $res = $this->_put_mt($mt);

			unless ( defined($res) ) {
				$connected->print("ERROR\n");    # Message was not saved
			} else {
				$connected->print("OK\n");       # All OK
			}
		}
		close $connected;
	} ## end while (1)

} ## end sub run

=item B<_put_mt> 

 Inserts into messages table MT message 

=cut 

sub _put_mt {

	my ( $this, $mt ) = @_;

	unless ( defined( $this->_connect_db() ) ) {
		return undef;
	}

	$mt = $this->_validate_mt($mt);
	$mt = $this->_convert_mt($mt);

	unless (
		defined(
			$this->msgsth->execute(
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

			)
		)
	  )
	{
		return undef;
	} ## end unless ( defined( $this->msgsth...

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

	if ( !$this->msgdbh or !$this->msgdbh->ping ) {
		$this->msgdbh( DBI->connect_cached( $dsn, $user, $passwd ) );

		if ( !$this->msgdbh ) {
			$this->speak("Cant connect to DBMS!");
			$this->log( "error", "Cant connect to DBMS!" );
			return undef;
		}
		my $sql = "insert into " . $table . " ( msg_type, esme_id, src_addr, dst_addr, body, coding, udh, mwi, mclass, message_id, validity, deferred, registered_delivery, service_type, extra, received ) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,? ) ";
		$this->msgsth( $this->msgdbh->prepare_cached($sql) );
	}
	return 1;

} ## end sub _connect_db

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


