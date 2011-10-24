#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  convert2utf8.pl
#
#        USAGE:  ./convert2utf8.pl 
#
#  DESCRIPTION:  
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Alex Radetsky (Rad), <rad@rad.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  10.12.2010 16:55:40 EET
#     REVISION:  ---
#===============================================================================

use 5.8.0;
use strict;
use warnings;

use Data::Dumper;
use DBI;
use NetSDS::Util::Convert;
use NetSDS::Util::String; 

use utf8;

unless ( defined ( $ARGV[0] ) ) { 
	warn "Usage: <msg_id>"; 
	exit -1;
}


my $dsn      = 'DBI:mysql:database=mydb;host=192.168.1.53';
my $user     = 'netstyle';
my $password = '';

my $dbh = DBI->connect_cached( $dsn, $user, $password );
unless ( defined($dbh) ) {
        die "fail: can't connect to database. DSN: '$dsn'\n";
}

my $msg_id = $ARGV[0]; 
my $sth = $dbh->prepare_cached ("select * from messages where id=?");
$sth->execute($msg_id);
my $msg = $sth->fetchrow_hashref();

my $hexcoded = $msg->{'body'};
my $coding = $msg->{'coding'}; 

if ($coding == 1) { 
	warn "It's a binary!";
    exit 0;
}

my $str = conv_hex_str ($hexcoded);

my $utf8str = undef; 

if ($coding == 0) { 
	$utf8str = str_recode($str,'gsm0338','utf8');
} 
if ($coding == 2) {
#	$utf8str = $str; 
#$str = str_encode($str, 'ucs2-be');
	$utf8str = str_recode($str,'ucs2-be','utf8');
}
unless (defined ($utf8str) ) {
	warn "String coding value: $coding";
} else {
	print "Result: ' $utf8str ' ". Dumper ($utf8str); 
}



1;
#===============================================================================

__END__

=head1 NAME

convert2utf8.pl

=head1 SYNOPSIS

convert2utf8.pl

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

