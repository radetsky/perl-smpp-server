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
use JSON;

use NetSDS::Util::Convert;

my $utf8text = conv_str_uri($ARGV[0]); 
my $coding = $ARGV[1]; 

unless ( ( defined ( $utf8text ) ) and ( defined ( $coding ) ) )  { 
	die "Usage: $0 text coding\n"; 
} 

my $dsn      = 'DBI:mysql:database=mydb;host=192.168.1.53';
my $user     = 'netstyle';
my $password = '';

my $dbh = DBI->connect_cached( $dsn, $user, $password );
unless ( defined($dbh) ) {
	die "fail: can't connect to database. DSN: '$dsn'\n";
}

my $sth = $dbh->prepare_cached("insert into smppd_messages ( msg_type, esme_id, src_addr, dst_addr, body, coding, udh, mwi, mclass, message_id, validity, deferred, registered_delivery, service_type, extra ) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,? ) ");
$sth->execute( 'MO', 3, '0504139380', 'smppsvrtst.pl', $utf8text ,$coding, undef, undef, 0, '1010101010101010101', 1440, undef, undef, undef,undef );

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

