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

package NetSDS::App::SMSTradeInQ;

use 5.8.0;
use strict;
use warnings;

use IO::Handle;
use IO::Socket qw(:DEFAULT :crlf);

use Time::HiRes qw(usleep);
use Data::Dumper;

use NetSDS::Util::Convert;
use JSON;

use base qw(NetSDS::App);

use constant MTQ_SOCK => "127.0.0.1:9998";    # From Database to SMPPD

use constant MYSQL_DSN    => 'DBI:mysql:database=mydb1;host=192.168.1.53';
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
__PACKAGE__->mk_accessors(qw/msgdbh/);
__PACKAGE__->mk_accessors(qw/msgsth/);

sub run {

	my ( $this, %params ) = @_;

	#  $this->mk_accessors('msgdbh');
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

	# here is the database read cycle

	while (1) {
		next unless my $connected = $mtq_socket->accept;
		$this->speak("[$$] SMSTradeInQ Something connected.");
		while (1) {
			my $recv_buf = $connected->getline;
			chomp $recv_buf;
			my $mt = from_json( conv_base64_str($recv_buf), { utf8 => 1 } );
			my $res = $this->_put_mt($mt);
			unless ( defined ( $res ) ) { 
				$connected->print("ERROR\n"); # Message was not saved
			} else {
				$connected->print("OK\n"); # All OK
			}
		}
		close $connected;
	}

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

	#	$mt->{'message_id'} = $mt->{'id'};     # Received from SMPPD MessageID as ID
	#	$mt->{'body'}       = $mt->{'ud'};
	#	$mt->{'src_addr'}   = $mt->{'from'};
	#	$mt->{'dst_addr'}   = $mt->{'to'};
	#	$mt->{'coding'} =  $mt->{'coding_integer'};

	return $mt;
}

sub _connect_db {

	my ( $this, @params ) = @_;

	my $dsn    = MYSQL_DSN;
	my $user   = MYSQL_USER;
	my $passwd = MYSQL_SECRET;

	if ( defined( $this->{conf}->{'in_queue'}->{'dsn'} ) ) {
		$dsn    = $this->{conf}->{'in_queue'}->{'dsn'};
		$user   = $this->{conf}->{'in_queue'}->{'db-user'};
		$passwd = $this->{conf}->{'in_queue'}->{'db-password'};
	}

	# If DBMS isn' t accessible - try reconnect

	if ( !$this->msgdbh or !$this->msgdbh->ping ) {
		$this->msgdbh( DBI->connect_cached( $dsn, $user, $passwd ) );

		if ( !$this->msgdbh ) {
			$this->speak("Cant connect to DBMS!");
			$this->log( "error", "Cant connect to DBMS!" );
			return undef;
		}
		my $sql = "insert into messages ( msg_type, esme_id, src_addr, dst_addr, body, coding, udh, mwi, mclass, message_id, validity, deferred, registered_delivery, service_type, extra, received ) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,? ) ";
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


