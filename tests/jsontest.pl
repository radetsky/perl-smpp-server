#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  jsontest.pl
#
#        USAGE:  ./jsontest.pl 
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
#      CREATED:  10.01.2011 21:59:32 EET
#     REVISION:  ---
#===============================================================================

use 5.8.0;
use strict;
use warnings;

use JSON; 
use Encode; 

my $str = $ARGV[0]; 
unless ( defined ( $str ) ) { 
	die "usage: <str>\n";
}

my $j = JSON->new()->utf8(1);

my $d = {
    a => decode('utf-8', $str),
    b => 12345,
};

print $j->encode($d);

1;
#===============================================================================

__END__

=head1 NAME

jsontest.pl

=head1 SYNOPSIS

jsontest.pl

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

