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
use NetSDS::Util::String; 

unless ( ( defined ($ARGV[0] ) ) or ( defined ( $ARGV[1] ) ) or ( defined ( $ARGV[2] ) ) ) {
	warn "Usage: <coding(0-2)> <Text> <count>";
	exit -1;
}

my $coding= $ARGV[0]; 
my $text  = $ARGV[1]; 
my $count = $ARGV[2]; 

# Test No. 1: TCP Connect to localhost : 9900.
my $cli = Net::SMPP->new_connect( 'localhost', port => 9900, smpp_version => 0x34, async => 1 );
if ($cli) {
	print "ok 1: connect to '127.0.0.1:9900:ver 3.4:async\n";
} else {
	die "fail 1: failed connect to 127.0.0.1:9900 : $!\n";
}

my $seq = undef; 
my $pdu = undef; 

$cli = Net::SMPP->new_connect( 'localhost', port => 9900, smpp_version => 0x34, async => 1 ) or die;
$seq = $cli->bind_transceiver( system_id => 'test1000', password => 'secret1000' ) or die;
$pdu = $cli->read_pdu() or die;
if ( $pdu->{status} == 0x00 ) {          ## STATUS
	print "ok 3 : correct answer for system_id->'SMSGW',password->'secret'. \n";
} else {
	die "fail 3: PDU->status must have 0x00 value. \n";
}

if ($coding == 2) { 
	$text = str_recode ($text, 'utf8', 'ucs2-be'); 
} 
if ($coding == 0) { 
	$text = str_recode ($text, 'utf8', 'gsm0338');
} 

use Benchmark ':hireswallclock'; 

my $t1 = new Benchmark; 

my $tt0 = [gettimeofday];

for (my $i = 0; $i < $count; $i++) { 
	# Test No. 4: Send SM
	$seq = $cli->submit_sm( 'data_coding' => ( $coding << 2 )  , 'source_addr' => 'smppsvrtst.pl', 'destination_addr' => '380504139380', short_message => $text ) or die;
	$pdu = $cli->read_pdu() or die;
} 

my $elapsed = tv_interval ( $tt0, [ gettimeofday ] );
my $t2 = new Benchmark; 
my $smspersec = $count / $elapsed; 
print "Sent " . $count . " messages. \n"; 
print "Used " . timestr (timediff ($t2, $t1), 'all') . "\n";  
print "Rate ~~ " . $smspersec  . "\n"; 
print "\n"; 



$cli->unbind();


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

