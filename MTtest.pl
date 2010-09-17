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

my $seq = undef; 
my $pdu = undef; 

my $cli = Net::SMPP->new_connect( 'localhost', port => 9900, smpp_version => 0x34, async => 1 ) or die;
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

$seq = $cli->unbind(); 
$pdu = $cli->read_pdu();


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

