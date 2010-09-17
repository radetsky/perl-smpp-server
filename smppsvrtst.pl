#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  smppsvrtst.pl
#
#        USAGE:  ./smppsvrtst.pl
#
#  DESCRIPTION:  Test cases for smppserver v 2.x
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Alex Radetsky (Rad), <rad@rad.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  29.08.10 20:56:45 EEST
#     REVISION:  ---
#===============================================================================

use 5.8.0;
use strict;
use warnings;

use Data::Dumper;
use Net::SMPP;
use Time::HiRes qw(gettimeofday tv_interval);

use DBI;

use NetSDS::Util::Convert; 

my $fail = 0;

my $dsn      = 'DBI:mysql:database=mydb;host=192.168.1.53';
my $user     = 'netstyle';
my $password = '';

sub fail_pdu {
	my ( $n, $pdu ) = @_;
	print "fail $n\n" . Dumper($pdu) . Net::SMPP::hexdump( $pdu->{data}, "\t" );
	$fail++;
}

# Test No. 1: TCP Connect to localhost : 9900.
my $cli = Net::SMPP->new_connect( 'localhost', port => 9900, smpp_version => 0x34, async => 1 );
if ($cli) {
	print "ok 1: connect to '127.0.0.1:9900:ver 3.4:async\n";
} else {
	die "fail 1: failed connect to 127.0.0.1:9900 : $!\n";
}

my $seq = undef; 
my $pdu = undef; 

# Test No. 2: Send empty bind_transceiver PDU.  Server must return PDU with error.
$seq = $cli->bind_transceiver() or die;
$pdu = $cli->read_pdu()         or die;
if ( $pdu->{status} == 0x0000000E ) {    ## INVALID PASSWORD
	print "ok 2: correct answer for empty bind_transceiever PDU. Invalid Password. \n";
} else {
	die "fail 2: PDU->status must have 0x0E value. \n";
}

# Test No. 3: Send correct bind_transceiver PDU. Server must return PDU with nornal status.
$cli = Net::SMPP->new_connect( 'localhost', port => 9900, smpp_version => 0x34, async => 1 ) or die;

$seq = $cli->bind_transceiver( system_id => 'SMSGW', password => 'secret' ) or die;
$pdu = $cli->read_pdu() or die;
if ( $pdu->{status} == 0x00 ) {          ## STATUS
	print "ok 3: correct answer for system_id->'SMSGW',password->'secret'. \n";
} else {
	die "fail 3: PDU->status must have 0x00 value. \n";
}

$seq = $cli->enquire_link(); 
$cli->read_pdu(); 


# Test No. 4: Send SM
$seq = $cli->submit_sm( 'data_coding' => '2', 'source_addr' => 'smppsvrtst.pl', 'destination_addr' => '380504139380', short_message => 'Test message from smppsvrtst.pl' ) or die;
$pdu = $cli->read_pdu() or die;
if ( $pdu->{status} == 0x00 ) {          ## STATUS
	print "ok 4: SM accepted.\n";
} else {
	die "fail 4: single message was not acccepted. PDU->status must be 0x00. \n";
}

my $t0 = [gettimeofday];

# Test No. 5: Send 1000 SMS

my $cli3 = Net::SMPP->new_connect( 'localhost', port => 9900, smpp_version => 0x34, async => 1 ) or die;
$seq = $cli3->bind_transceiver( system_id => 'test1000', password => 'secret1000' ) or die;

for (my $cx = 0; $cx < 1000; $cx++ ) {
	$seq = $cli3->submit_sm('destination_addr' => '380504139380', short_message => 'Test message from smppsvrtst.pl') or die;
	$pdu = $cli3->read_pdu() or die;
	if ($pdu->{status} != 0x00 ) { ## STATUS
		die "fail 5: multiple message was not acccepted. PDU->status must be 0x00. \n";
	}
}


# unbind and close 
$cli3->unbind() or die; 


my $elapsed = tv_interval ( $t0, [ gettimeofday ] );
my $smspersec = 1000/$elapsed;
print "ok 5: 1000 SMS per $elapsed seconds ~~ $smspersec \n";


# Test No. 6: Receive SM
my $dbh = DBI->connect_cached( $dsn, $user, $password );
unless ( defined($dbh) ) {
	die "fail 6: can't connect to database. DSN: '$dsn'\n";
}

my $sth = $dbh->prepare_cached("insert into messages ( msg_type, esme_id, src_addr, dst_addr, body, coding, udh, mwi, mclass, message_id, validity, deferred, registered_delivery, service_type, extra, received ) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,? ) ");
$sth->execute( 'MO', 1, '0504139380', 'smppsvrtst.pl', conv_str_hex('bla-bla-bla'), 2, undef, undef, undef, '1010101010101010101', 1440, undef, undef, undef, undef, '2010-08-30 23:59:00' );
$pdu = $cli->read_pdu();
warn Dumper($pdu);
print "ok 6: receive SM\n";

# Test No. 7. Insert 1000 SM to database

$t0 = [ gettimeofday ];
for (my $cx = 0; $cx < 1000; $cx++ ) {
	$sth->execute( 'MO',1,'0504139380','smppsvrtst.pl',conv_str_hex('bla-bla-bla'),0,undef,undef,undef,'1010101010101010101',1440,undef,undef,undef,undef,'2010-08-30 23:59:00');
};

$elapsed = tv_interval ( $t0, [ gettimeofday ] );
$smspersec = 1000/$elapsed;
print "ok 7: inserted 1000 SMS per $elapsed seconds ~~ $smspersec \n";

# Test No 8. Receive 1000 SM from SMPPD

$t0 = [ gettimeofday ];
for (my $cx = 0; $cx < 1000; $cx++) {
	$pdu = $cli->read_pdu();
}
$elapsed = tv_interval ( $t0, [ gettimeofday ] );
$smspersec = 1000/$elapsed;
print "ok 8: received 1000 SMS per $elapsed seconds ~~ $smspersec \n";

# Test No 9. Sending enquire-lik 

$seq = $cli->enquire_link() 
		or die "Can't send enquire link PDU.\n"; 
$pdu = $cli->read_pdu(); 
warn Dumper ($pdu); 

print "ok 9: send and receive PDU.\n"; 


# Test No. 10: TCP Connect to localhost : 9900. Second 
my $cli2 = Net::SMPP->new_connect( 'localhost', port => 9900, smpp_version => 0x34, async => 1 );
if ($cli) {
	print "ok 10: connect to '127.0.0.1:9900:ver 3.4:async more than 1 times\n";
} else {
	die "fail 10: failed connect to 127.0.0.1:9900 : $!\n";
}

# Test No. 11: New bind transciever . 
$seq = $cli2->bind_transceiver( system_id => 'SMSGW', password => 'secret' ) or die;
$pdu = $cli2->read_pdu() or die;
if ( $pdu->{status} == 0x0E) {          ## STATUS
	print "ok 11: can't connect more than 1 time for SMSGW with NULL (default 1) max_connections.\n"; 
} else { 
	warn Dumper ($pdu); 
	die "fail 11: SMPP authenticated more than 1 time. WRONG!\n"; 
}


# Test No. 12. Send submit_sb withh invalid src addr 

$seq = $cli->submit_sm( 'data_coding' => '2', 'source_addr' => 'INVALID', 'destination_addr' => '380504139380', short_message => 'Test message from INVALID' ) or die;
$pdu = $cli->read_pdu() or die;
if ( $pdu->{status} == 0x00 ) {          ## STATUS
    die "fail 12: SMS submitted with wrong ALPHANUM name\n"; 
} else {
	warn Dumper ($pdu); 
    print "ok 12: SMS failed from INVALID.\n"; 
}

#Test No. 13 : Throttling 
$seq = $cli->submit_sm( 'data_coding' => '2', 'source_addr' => 'smppsvrtst.pl', 'destination_addr' => '380504139380', short_message => 'Test message from smppsvrtst.pl' ) or die;
$pdu = $cli->read_pdu() or die;
$seq = $cli->submit_sm( 'data_coding' => '2', 'source_addr' => 'smppsvrtst.pl', 'destination_addr' => '380504139380', short_message => 'Test message from smppsvrtst.pl' ) or die;
$pdu = $cli->read_pdu() or die;
if ( $pdu->{status} == 0x58 ) {          ## STATUS
    print "ok 13: SM failed for THROTTLING reason.\n";
} else {
    die "fail 13: TWO messages was acccepted, but bandwidth value is 1. \n";
}

# Test No. 14 : 1000 connects 

print "Test No. 14. Creating 1000 connects and bind_transciever.\n"; 
my @many_connects = (); 

for (my $x = 0; $x < 1000; $x++) { 
	my $smpp =  Net::SMPP->new_connect( 'localhost', port => 9900, smpp_version => 0x34, async => 1 ) or die; 
	unless ( defined ($smpp) ) { 
	    die "fail 14: failed connect to 127.0.0.1:9900 in $x connect : $!\n";
	} 
	my $smpp_seq = $smpp->bind_transceiver( system_id => 'test1000', password => 'secret1000' ) or die;
    unless ( defined ($smpp_seq) ) { 
		die "fail 14: failed bind_transciever() in $x connect : $!\n"; 
	}
	my $smpp_pdu = $smpp->read_pdu() or die;  
	if ($smpp_pdu->{status} != 0x00) { 
		die "fail 14: pdu->status != 0x00 in $x \n"; 
	} 
	push @many_connects,$smpp; 
	#print "already connected: ".($x+1)."\n"; 

}

print "Test No. 14. Complete. 1000 sockets created. \n"; 



#############################################################################

### The end

if ($fail) {
	print "*** Bummer. $fail tests failed.\n";
} else {
	print "All tests successful.\n";
}

exit;

### Debugging section

for my $test (qw(abcdefgh abcdefg abcedf abcde abcd abc ab a abcdefghi abcdefghij abcdefghabcdefgh)) {
	print "Testing >$test< len=" . length($test) . "\n";
	my $x = Net::SMPP::pack_7bit($test);
	my $y = Net::SMPP::unpack_7bit($x);
	print "        >$y< len=" . length($y) . "\n";
	print Net::SMPP::hexdump( $x, "\t" );
	print Net::SMPP::hexdump( $y, "\t" );
}

#EOF

1;
#===============================================================================

__END__

=head1 NAME

smppsvrtst.pl

=head1 SYNOPSIS

smppsvrtst.pl

=head1 DESCRIPTION

FIXME

=head1 EXAMPLES

FIXME

=head1 BUGS

Unknown.

=head1 TODO

Empty.

=head1 AUTHOR

Alex Radetsky <rad@rad.kiev.ua>

=cut

