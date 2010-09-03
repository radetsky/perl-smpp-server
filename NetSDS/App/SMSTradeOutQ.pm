#===============================================================================
#
#         FILE:  SMSTradeOutQ.pm
#
#  DESCRIPTION:  Plugin for send Mobile Originated Messages to SMPPServerV2
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

package NetSDS::App::SMSTradeOutQ;

use 5.8.0;
use strict;
use warnings;

use IO::Handle;
use IO::Socket qw(:DEFAULT :crlf);

use JSON;
use Time::HiRes qw( usleep );

use Data::Dumper;
use NetSDS::Util::Convert;
use JSON;

use base qw(NetSDS::App);

use constant MOQ_SOCK => "127.0.0.1:9999";    # From Database to SMPPD

use constant MYSQL_DSN    => 'DBI:mysql:database=mydb;host=192.168.1.53';
use constant MYSQL_USER   => 'netstyle';
use constant MYSQL_SECRET => '';

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

=item B<user(...)> - object method

=cut

#-----------------------------------------------------------------------
#__PACKAGE__->mk_accessors('user');
__PACKAGE__->mk_accessors(qw/msgdbh/);
__PACKAGE__->mk_accessors(qw/msgsth/);

sub run {

	my ( $this, %params ) = @_;

	$this->_connect_db;

	my $moq_socket = IO::Socket::INET->new(
		LocalAddr => MOQ_SOCK,
		Type      => SOCK_STREAM,
		Listen    => 1,
		ReuseAddr => 1,
		Proto     => 'tcp',
	);

	unless ( defined($moq_socket) ) {
		warn "[$$] SMSTradeOutQ Create socket error : $!\n";
		die;
	}

	$moq_socket->autoflush(1);

	# here is the database read cycle

	while (1) {
		next unless my $connected = $moq_socket->accept;
		$this->speak("[$$] SMSTradeOutQ Something connected.");
		while (1) {
			# Here we will be read database
			my $queue_msg = $this->_get_mo;
			unless ( defined($queue_msg) ) {    # No more records
				                                #sleep(500);
				sleep(1);
				next;
			}

			$queue_msg = $this->_validate_mo($queue_msg);

			my $json_text = to_json( $queue_msg, { ascii => 1, pretty => 1 } );
			# Sending to SMPPd
			my $res = $connected->print( conv_str_base64($json_text) . "\n" );

			# FIXME : дождаться подтверждения того, что сообщение послано.
			# И только после этого удалить, иначе не удалять.

			my $confirm = $connected->getline;
			if ( $confirm =~ /OK/ ) {
				$this->_delete_mo( $queue_msg->{'internal_id'} );
			} else {
				# FIXME : это не должен быть sleep.
				sleep(1);
			}

		} ## end while (1)
		close $connected;
	} ## end while (1)
} ## end sub run

sub _validate_mo {
	my ( $this, $mo ) = @_;

	#$mo->{'to'}          = $mo->{'dst_addr'};
	#$mo->{'from'}        = $mo->{'src_addr'};
	$mo->{'internal_id'} = $mo->{'id'};                     # Key to delete message
	$mo->{'id'}          = $mo->{'message_id'};             # UUID message id
	$mo->{'text'}        = conv_hex_str( $mo->{'body'} );
	#$mo->{'data_coding'} = $mo->{'coding'};

	return $mo;
}

sub _delete_mo {
	my ( $this, $mo_id ) = @_;

	$this->msgdbh->do("delete from messages where id=$mo_id");

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

	# If DBMS isn' t accessible - try reconnect

	if ( !$this->msgdbh or !$this->msgdbh->ping ) {
		$this->msgdbh( DBI->connect_cached( $dsn, $user, $passwd ) );
	}

	if ( !$this->msgdbh ) {
		$this->speak("Cant connect to DBMS!");
		$this->log( "error", "Cant connect to DBMS!" );
		die;
	}

	if ( !$this->msgsth ) {
		$this->msgsth( $this->msgdbh->prepare_cached("select id,msg_type,esme_id,src_addr,dst_addr,body,coding,message_id from messages where msg_type='MO' or msg_type='DLR';") );
	}

} ## end sub _connect_db

sub _get_mo {

	my ( $this, @params ) = @_;

	$this->_connect_db;

	$this->msgsth->execute();

	my $res = $this->msgsth->fetchrow_hashref;

	return $res;

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


