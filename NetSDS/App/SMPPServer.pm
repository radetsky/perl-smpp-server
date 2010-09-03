#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  smppd.pl
#
#        USAGE:  ./smppd.pl
#
#  DESCRIPTION:  NetSDS SMPP Server
#
#      OPTIONS:  ---
# REQUIREMENTS:
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  12.07.2009 15:15:03 UTC
#     REVISION:  ---
#     MODIFIED:  Alex Radetsky (rad), <rad@rad.kiev.ua>
#     MODIFYDATE: 2010-08-24 ( Ukrainian Independence Day ) 
#===============================================================================

=head1 NAME

NetSDS::App::SMPPD - Ready SMPP-server to use. Works with smppqproc.pl and MemcacheQ.

=cut 

=head1 SYNOPSIS 


MySuperPuperNewSMPPServer->run ( 
	daemon  => 1,
	verbose => 0,
  use_pidfile => 1,
); 

1; 

package MySuperPuperNewSMPPServer; 

use base qw(NetSDS::App::SMPPServer); 

1; 


=cut 

=head1 DESCRIPTION 

C<NetSDS> module contains ready SMPP-server. 

=cut 



use 5.8.0;
use strict;
use warnings;

package NetSDS::App::SMPPServer;

use 5.8.0;
use strict;
use warnings;

use base qw(NetSDS::App::SMPP);

use NetSDS::Util::Convert;
use NetSDS::Util::DateTime;
use NetSDS::Util::String;
use NetSDS::Util::Misc;
use NetSDS::Queue;

use IPC::ShareLite;
use JSON;

use DBI;

use Time::HiRes qw(usleep);

use Data::Dumper;

sub start {

	my ($this) = @_;

	# Connect to authentication DBMS
	$this->mk_accessors('authdbh');
	$this->_connect_db;

}

#
# bind_transiever called when ESME connect to us in transiever mode (send and receive SMS in one connection ) 
#

sub cmd_bind_transceiver {

	my ( $this, $pdu, $hdl ) = @_;

	# Determine incoming login (system-id) and password
	my $login  = $pdu->{system_id};
	my $passwd = $pdu->{password};

	my $resp_status = 0x00000000;    # All OK

	# Send error status if already authenticated
	if ( $hdl->{authenticated} ) {

		$this->log( "warning", "Already binded ESME authentication: $login" );
		$resp_status = 0x00000005;    # Already in bind state

	} else {

		# Authentication
		if ( $this->_auth_esme( $login, $passwd ) ) {
			$this->speak("ESME '$login' successfully authenticated");
			$this->log( "info", "ESME '$login' successfully authenticated" );

			# Update handlers
			$this->{handlers}->{ $hdl->{id} }->{authenticated} = 1;
			$this->{handlers}->{ $hdl->{id} }->{system_id}     = $login;
			$this->{handlers}->{ $hdl->{id} }->{mode}          = 'transceiver';

			# Update SHM struture
			my $list = decode_json( $this->shm->fetch );
			$list->{$login} = 1;
			$this->shm->lock;
			$this->shm->store( encode_json($list) );
			$this->shm->unlock;

		} else {
			$this->log( "warning", "Cant authenticate ESME: [$login:$passwd]" );
			$this->speak("Cant authenticate ESME: [$login:$passwd]");
			$resp_status = 0x0000000E;    # ESME_RINVPASWD
		}

		my $resp = $hdl->{smpp}->bind_transceiver_resp(
			seq       => $pdu->{seq},
			status    => $resp_status,                     # ESME_ROK
			system_id => NetSDS::App::SMPP::SYSTEM_NAME,
		);

	} ## end else [ if ( $hdl->{authenticated...

} ## end sub cmd_bind_transceiver

sub cmd_bind_transmitter {

	my ( $this, $pdu, $hdl ) = @_;

	# Determine incoming login (system-id) and password
	my $login  = $pdu->{system_id};
	my $passwd = $pdu->{password};

	my $resp_status = 0x00000000;    # All OK

	# Send error status if already authenticated
	if ( $hdl->{authenticated} ) {

		$this->log( "warning", "Already binded ESME authentication: $login" );
		$resp_status = 0x00000005;    # Already in bind state

	} else {

		# FIXME
		# Authentication
		if ( $this->_auth_esme( $login, $passwd ) ) {
			$this->speak("ESME '$login' successfully authenticated");
			$this->log( "info", "ESME '$login' successfully authenticated" );

			# Update handlers
			$this->{handlers}->{ $hdl->{id} }->{authenticated} = 1;
			$this->{handlers}->{ $hdl->{id} }->{system_id}     = $login;
			$this->{handlers}->{ $hdl->{id} }->{mode}          = 'transmitter';

		} else {
			$this->log( "warning", "Cant authenticate ESME: [$login:$passwd]" );
			$this->speak("Cant authenticate ESME: [$login:$passwd]");
			$resp_status = 0x0000000E;    # ESME_RINVPASWD
		}

		my $resp = $hdl->{smpp}->bind_transmitter_resp(
			seq       => $pdu->{seq},
			status    => $resp_status,                     # ESME_ROK
			system_id => NetSDS::App::SMPP::SYSTEM_NAME,
		);

	} ## end else [ if ( $hdl->{authenticated...

} ## end sub cmd_bind_transmitter

sub cmd_bind_receiver {

	my ( $this, $pdu, $hdl ) = @_;

	# Determine incoming login (system-id) and password
	my $login  = $pdu->{system_id};
	my $passwd = $pdu->{password};

	my $resp_status = 0x00000000;    # All OK

	# Send error status if already authenticated
	if ( $hdl->{authenticated} ) {

		$this->log( "warning", "Already binded ESME authentication: $login" );
		$resp_status = 0x00000005;    # Already in bind state

	} else {

		# FIXME
		# Authentication
		if ( $this->_auth_esme( $login, $passwd ) ) {
			$this->speak("ESME '$login' successfully authenticated");
			$this->log( "info", "ESME '$login' successfully authenticated" );

			# Update handlers
			$this->{handlers}->{ $hdl->{id} }->{authenticated} = 1;
			$this->{handlers}->{ $hdl->{id} }->{system_id}     = $login;
			$this->{handlers}->{ $hdl->{id} }->{mode}          = 'receiver';

			# Update SHM struture
			my $list = decode_json( $this->shm->fetch );
			$list->{$login} = 1;
			$this->shm->lock;
			$this->shm->store( encode_json($list) );
			$this->shm->unlock;

		} else {
			$this->log( "warning", "Cant authenticate ESME: [$login:$passwd]" );
			$this->speak("Cant authenticate ESME: [$login:$passwd]");
			$resp_status = 0x0000000E;    # ESME_RINVPASWD
		}

		my $resp = $hdl->{smpp}->bind_receiver_resp(
			seq       => $pdu->{seq},
			status    => $resp_status,                     # ESME_ROK
			system_id => NetSDS::App::SMPP::SYSTEM_NAME,
		);

	} ## end else [ if ( $hdl->{authenticated...

} ## end sub cmd_bind_receiver

sub cmd_submit_sm {

	my ( $this, $pdu, $hdl ) = @_;

	my %COD_NAME = (
		0 => 'gsm0338',
		1 => '8bit',
		2 => 'ucs2',
	);

	my $resp_status = undef;    # response command status
	my $message_id  = undef;    # message id on CPA (UUID style)

	# Check if client is authenticated
	if ( $hdl->{authenticated} ) {

		# Create empty message
		my $queue_msg = {
			client  => $hdl->{system_id},
			created => date_now(),
		};

		my $mclass = undef;     # default (ME specific according with GSM 03.38)

		# Create UUID for new MT message
		$message_id = make_uuid();
		$queue_msg->{id} = $message_id;

		# Get source and destination addresses
		my $src_addr = $pdu->{source_addr};
		my $dst_addr = $pdu->{destination_addr};
		$queue_msg->{from} = $src_addr;
		$queue_msg->{to}   = $dst_addr;

		# **************************************************************************
		#
		# Process data_coding (see ETSI GSM 03.38 specification)
		#
		# Determine: message_class, coding, MWI flags
		#
		my $data_coding = $pdu->{data_coding};

		# Check if message_class is present
		if ( ( $data_coding & 0b00010000 ) eq 0b00010000 ) {
			$mclass = $data_coding & 0b00000011;
		}
		$queue_msg->{mclass} = $mclass;

		# Determine coding
		my $coding = ( $data_coding & 0b00001100 ) >> 2;

		$queue_msg->{coding} = $COD_NAME{$coding};

		# Determine UDHI state
		my $udhi      = 0;                    # No UDH by default
		my $esm_class = $pdu->{esm_class};    # see 5.2.12 part of SMPP 3.4 spec
		if ( ( $esm_class & 0b01000000 ) eq 0b01000000 ) {
			$udhi = 1;
		}

		# **************************************************************************
		#
		# Process SM body (UD and UDH)
		#
		my $msg_text = $pdu->{short_message};

		# If have UDH, get if from message
		my $udh = undef;
		if ($udhi) {
			use bytes;
			my ($udhl) = unpack( "C*", bytes::substr( $msg_text, 0, 1 ) );
			$udh = bytes::substr( $msg_text, 0, $udhl + 1 );
			$msg_text = bytes::substr( $msg_text, $udhl + 1 );
			no bytes;
			$queue_msg->{udh} = conv_str_hex($udh);
		}

		# Encode User Data (UD)
		my $ud = $msg_text;
		if ( $coding eq 2 ) {
			$msg_text = str_encode( $msg_text, 'UCS-2BE' );    # encode from UCS-2 string
			$ud       = str_decode( $msg_text, 'UCS-2BE' );
		} else {
			$msg_text = str_encode($msg_text);
			$ud       = str_decode($msg_text);
		}
		$queue_msg->{ud}   = conv_str_hex($ud);
		$queue_msg->{text} = $msg_text;

		# Check if need DLR for message
		if ( $pdu->{registered_delivery} ) {
			$queue_msg->{register_delivery} = '1';
		}

		# Determine TTL for the message
		my $validity_period = $pdu->{validity_period};
		if ( $validity_period =~ /(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d)(\d\d)([\-\+R])/ ) {
			$queue_msg->{validity} = "20" . $1 . "-" . $2 . "-" . $3 . " " . $4 . ":" . $5 . ":" . $6;
		}

		# Determine deferred delivery time
		my $schedule_delivery_time = $pdu->{schedule_delivery_time};
		if ( $schedule_delivery_time =~ /(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d)(\d\d)([\-\+R])/ ) {
			$queue_msg->{deferred} = "20" . $1 . "-" . $2 . "-" . $3 . " " . $4 . ":" . $5 . ":" . $6;
		}

		# Determine priority
		if ( $pdu->{priority_flag} ) {
			$queue_msg->{priority} = $pdu->{priority_flag} + 0;
		}

		$this->log( "info", "MT SM submitted: id='$message_id', from='$src_addr', to='$dst_addr'" );
		my $res = $this->in_queue->push( "q_mt", $queue_msg );
		if ( !$res ) {
			$resp_status = 0x45;    # ESME_RSUBMITFAIL
		}

	} else {
		$resp_status = 0x45;    # ESME_RSUBMITFAIL
	} ## end if ( $hdl->{authenticated...

	# Send response to ESME
	# Note: we use asynchronous sending to avoid deadlocks
	$hdl->{smpp}->submit_sm_resp(
		seq        => $pdu->{seq},
		status     => $resp_status,
		message_id => $message_id,
		async      => 1,
	);

} ## end sub cmd_submit_sm

sub _auth_esme {

	my ( $this, $login, $passwd ) = @_;

	# Check DBMS connection and do reconnect if necessary
	$this->_connect_db();

	# Execute SQL query (should be present in configuration file)
	my $sth = $this->authdbh->prepare( $this->conf->{auth}->{query} );
	$sth->execute( $login, $passwd );

	# Try to get one row or return undef
	if ( my $res = $sth->fetchrow_hashref() ) {
		return 1;
	} else {
		return undef;
	}
}

sub _connect_db {

	my ($this) = @_;

	my $dsn    = $this->conf->{'auth'}->{'dsn'};
	my $user   = $this->conf->{'auth'}->{'db-user'};
	my $passwd = $this->conf->{'auth'}->{'db-password'};

	# If DBMS isn' t accessible - try reconnect
	if ( !$this->authdbh or !$this->authdbh->ping ) {
		$this->authdbh( DBI->connect_cached( $dsn, $user, $passwd ) );
		$this->authdbh->do("SET CLIENT_ENCODING TO 'UTF-8'");
		$this->authdbh->do("SET DATESTYLE TO 'ISO'");
	}

	if ( !$this->authdbh ) {
		$this->speak("Cant connect to DBMS!");
		$this->log( "error", "Cant connect to DBMS!" );
	}

} ## end sub _connect_db

1;
#===============================================================================

__END__

=head1 NAME

smppd.pl

=head1 SYNOPSIS

smppd.pl

=head1 DESCRIPTION

FIXME

=head1 EXAMPLES

FIXME

=head1 BUGS

Unknown.

=head1 TODO

Empty.

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=cut

