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


# Test No. 6: Receive SM
my $dbh = DBI->connect_cached( $dsn, $user, $password );
unless ( defined($dbh) ) {
	die "fail 6: can't connect to database. DSN: '$dsn'\n";
}

my $sth = $dbh->prepare_cached("insert into messages ( msg_type, esme_id, src_addr, dst_addr, body, coding, udh, mwi, mclass, message_id, validity, deferred, registered_delivery, service_type, extra, received ) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,? ) ");
$sth->execute( 'MO', 1, '0504139380', 'smppsvrtst.pl', conv_str_hex('bla-bla-bla'), 2, undef, undef, undef, '1010101010101010101', 1440, undef, undef, undef, undef, '2010-08-30 23:59:00' );

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

