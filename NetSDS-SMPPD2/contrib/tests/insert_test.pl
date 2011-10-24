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

my $count = $ARGV[0];
unless ( defined ($count ) ) { 
	die "Usage: <count>\n";
} 


my $dsn      = 'DBI:mysql:database=mydb;host=192.168.1.53';
my $user     = 'netstyle';
my $password = '';

# Test No. 6: Receive SM
my $dbh = DBI->connect_cached( $dsn, $user, $password );
unless ( defined($dbh) ) {
	die "fail 6: can't connect to database. DSN: '$dsn'\n";
}

my $sth = $dbh->prepare_cached("insert into smppd_events(event_name,src_addr_port,system_id,cmd_id,cmd_status,src,dst,userfield,text) values (?,?,?,?,?,?,?,?,?);");

$dbh->begin_work; 

my $t0 = [ gettimeofday ];
for (my $cx = 0; $cx < $count; $cx++ ) {
	$sth->execute( 'Submit_test','127.0.0.1:1270','submit_test',4,0,'test','test','{"message_id":"A36B3D04-1E82-11E0-9686-BC3CFD6E2402","seq":7}','1010101010101010101');
};


$dbh->commit; 

my $elapsed = tv_interval ( $t0, [ gettimeofday ] );
my $smspersec = $count/$elapsed;
print "ok 7: inserted $count SMS per $elapsed seconds ~~ $smspersec \n";

my @bind = ( 'Submit_test','127.0.0.1:1270','submit_test',4,0,'test','test','{"message_id":"A36B3D04-1E82-11E0-9686-BC3CFD6E2402","seq":7}','1010101010101010101');

$dbh->begin_work; 

$t0 = [ gettimeofday ];
for (my $cx = 0; $cx < $count; $cx++ ) {
	$sth->execute(@bind)
};

$dbh->commit; 

$elapsed = tv_interval ( $t0, [ gettimeofday ] );
$smspersec = $count/$elapsed;
print "ok 8: inserted $count SMS per $elapsed seconds ~~ $smspersec \n";

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

