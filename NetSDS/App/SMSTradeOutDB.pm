#===============================================================================
#
#         FILE:  SMSTradeOutDB.pm
#
#  DESCRIPTION:  Plugin for send Mobile Originated Messages to SMPPServerV2
#                This plugin reads messages from database for all connected ESME's
#                and send it to SMPPServer via local TCP-socket.
#
#        NOTES:  ---
#       AUTHOR:  Alex Radetsky (Rad), <rad@rad.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  24.08.10 17:14:18 EEST
#===============================================================================

=head1 NAME

NetSDS::

=head1 SYNOPSIS

	use NetSDS::;

=head1 DESCRIPTION

C<NetSDS> module contains superclass all other classes should be inherited from.

=cut

package NetSDS::App::SMSTradeOutDB;

use 5.8.0;
use strict;
use warnings;

use Data::Dumper;
use NetSDS::Util::Convert;
use NetSDS::Util::String;
use JSON; 

use base qw(NetSDS::App);

use constant MOQ_SOCK => "127.0.0.1:9999";    # From Database to SMPPD

use constant MYSQL_DSN    => 'DBI:mysql:database=mydb;host=192.168.1.53';
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
	my $class = shift;
	my $shm = shift; 
	my $conf = shift;   

	my $this = $class->SUPER::new();
	$this->{shm} = $shm; 
	$this->{conf} = $conf; 

	return $this;

}

#***********************************************************************

=head1 OBJECT METHODS

=over

=item B<user(...)> - object method

=cut

#-----------------------------------------------------------------------
#__PACKAGE__->mk_accessors('user');
__PACKAGE__->mk_accessors(qw/msgdbh/);
__PACKAGE__->mk_accessors(qw/msgsth/);

sub _process_mo_dlr {

	my ( $this, %params ) = @_;
	$this->_connect_db;

	# Here we will be read database
	my $queue_msgs = $this->_get_mo;
	my $count      = keys %$queue_msgs;
	if ( $count == 0 ) {    # No more records
		return 0; 
	}
	$this->log("info","Fetched $count messages from DB for delivery");

	my $res = {};
	# Read some messages MO and DLR
	foreach my $msg ( keys %$queue_msgs ) {
			my $queue_msg = $queue_msgs->{$msg};
			$this->log( 'debug', Dumper($queue_msg) ) if ( $this->{'debug'} );
			$queue_msg = $this->_validate_mo($queue_msg);
			if ( defined( $queue_msg->{'extra'} ) ) {
				$queue_msg = $this->_extra_decode($queue_msg);
			}
			$res->{$msg} = $queue_msg;  
	} ## end foreach my $msg ( keys %$queue_msgs)
	return $res; 

} ## end sub run

sub _validate_mo {
	my ( $this, $mo ) = @_;

	$mo->{'internal_id'} = $mo->{'id'};            # Key to delete message
	$mo->{'id'}          = $mo->{'message_id'};    # UUID message id

	#
	# DLR stay untouched. MO converts from URLEncoded str to given coding.
	#
	if ( $mo->{'msg_type'} eq 'MO' ) {
		$mo->{'text'} = $this->_convert_mo( $mo->{'body'}, $mo->{'coding'} );
	} else {
		$mo->{'text'} = $mo->{'body'};
	}
	return $mo;
} ## end sub _validate_mo

=item B<_convert_mo> 

Waits for URLEncoded string as first parameter and message coding (0..3) as second parameter. 
In case of coding eq 1 or 3 (bin, latin1) just urldecoding message.
In case of coding eq 0 or 2 (gsm0338,ucs2) try to convert it to given coding.
Returns: message body in given coding. 

=cut 

sub _convert_mo {
	my ( $this, $srcstr, $coding ) = @_;

	my @smpp_encoding = ( 'gsm0338', 'binary', 'ucs2-be', 'latin1' );
	my $dststr        = $srcstr;

	# First of all try to URL decode string.
	if ( defined( $this->{conf}->{'mo'}->{'body_translate'}->{'urldecode'} ) ) {
		if ( $this->{conf}->{'mo'}->{'body_translate'}->{'urldecode'} =~ /yes/i ) {
			$dststr = conv_uri_str($srcstr);
		}
	}

	if ( defined( $this->{conf}->{'mo'}->{'body_translate'} ) ) {
		# Body translate config found
		if ( defined( $this->{conf}->{'mo'}->{'body_translate'}->{$coding} ) ) {
			$dststr = str_recode(
				$dststr,
				$this->{conf}->{'mo'}->{'body_translate'}->{$coding},
				$smpp_encoding[$coding]
			);
		}
	} else {
		# Do it by default
		if ( $coding == 0 ) {
			$dststr = str_recode( $dststr, 'utf8', 'gsm0338' );
		}
		if ( $coding == 2 ) {
			$dststr = str_recode( $dststr, 'UTF-16BE', 'ucs2-be' );
		}
	}

	return $dststr;

} ## end sub _convert_mo

sub _extra_decode {

	my ( $this, $mo ) = @_;

	my $extra = decode_json( $mo->{'extra'} );
	undef $mo->{'extra'};

	foreach my $parameter ( keys %$extra ) {
		if ( $parameter =~ /message_state/i ) {
			$mo->{$parameter} = pack( "c", $extra->{$parameter} );
			next;
		}
		if ( $parameter =~ /receipted_message_id/i ) {
			$mo->{$parameter} = $extra->{$parameter} . chr(0);
			next;
		}
		$mo->{$parameter} = $extra->{$parameter};
	}
	return $mo;

} ## end sub _extra_decode

sub _delete_mo {
	my ( $this, $mo_id ) = @_;

	my $table = MYSQL_TABLE;

  if ( defined( $this->{conf}->{'out_queue'}->{'table'} ) ) {
		$table = $this->{conf}->{'out_queue'}->{'table'};
	}

  $this->_connect_db;
	$this->msgdbh->do( "delete from " . $table . " where id=$mo_id" );

}

sub _connect_db {

	my ( $this, @params ) = @_;

	my $dsn    = MYSQL_DSN;
	my $user   = MYSQL_USER;
	my $passwd = MYSQL_SECRET;

	if ( defined( $this->{conf}->{'out_queue'}->{'dsn'} ) ) {
		$dsn    = $this->{conf}->{'out_queue'}->{'dsn'};
		$user   = $this->{conf}->{'out_queue'}->{'db-user'};
		$passwd = $this->{conf}->{'out_queue'}->{'db-password'};
	}
	while (1) {
		# If DBMS isn' t accessible - try reconnect

		if ( !$this->msgdbh or !$this->msgdbh->ping ) {
			$this->msgdbh( DBI->connect_cached( $dsn, $user, $passwd, { RaiseError => 1 } ) );
		}

		if ( !$this->msgdbh ) {
			$this->log( "error", "Cant connect to DBMS! Waiting for 30 sec." );
			sleep(30);
			next;
		}

    if ( defined ( $this->{conf}->{'out_queue'}->{'mysql-set-names'} ) ) {
			    my $q = 'set names ' . $this->{conf}->{'in_queue'}->{'mysql-set-names'};
					$this->msgdbh->do ($q);
		}
		
		last;
	}

} ## end sub _connect_db

sub _get_mo {

	my ( $this, @params ) = @_;
	$this->_connect_db;

	my $table = MYSQL_TABLE;
	if ( defined( $this->{conf}->{'out_queue'}->{'table'} ) ) {
		$table = $this->{conf}->{'out_queue'}->{'table'};
	}

	my $query = undef;
	my $res   = {};

	# List active EMSEs
	my $list          = decode_json( $this->{shm}->fetch );
	my $my_local_data = defined( $this->conf->{'shm'}->{'magickey'} ) ? $this->conf->{'shm'}->{'magickey'} : 'My L0c4l D4t4';

		foreach my $login ( keys %$list ) {
			if ( $login eq $my_local_data ) {
				next;
			}

			my $mode      = $list->{$login}->{'mode'};
			my $bandwidth = $list->{$login}->{'bandwidth'};
			my $esme_id   = $list->{$login}->{'esme_id'};

			if ( ( $mode eq 'transciever' ) or ( $mode eq 'receiver' ) ) {
				$query = "select id,msg_type,esme_id,src_addr,dst_addr,body,coding,udh,mwi,mclass,validity,deferred,message_id,registered_delivery,service_type,extra from " . $table . " where msg_type='MO' or msg_type='DLR' and esme_id = $esme_id order by id limit $bandwidth";
				$this->log( "debug", "MO-DLR query: $query" ) if ( $this->debug );
				my $res_esme = $this->msgdbh->selectall_hashref( $query, "id" );
				$res = { %$res, %$res_esme };
			}
		}

	$this->log( "debug", "Returning " . keys(%$res) . " messages to push out." ) if ( $this->debug );
	return $res;

} ## end sub _get_mo

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


