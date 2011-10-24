#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  smppconvert.pl
#
#        USAGE:  ./smppconvert.pl 
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
#      CREATED:  10.01.2011 19:23:26 EET
#     REVISION:  ---
#===============================================================================

use 5.8.0;
use strict;
use warnings;

use lib '../'; 

use NetSDS::Util::SMPPConvert; 
use Data::Dumper; 

my $in = "Привет, мир!";
print $in . "\n"; 
my $out = conv_utf8_gsm($in,2); 

my $dst = conv_gsm_utf8($out,2); 
warn Dumper ($dst); 

1;
#===============================================================================

__END__

=head1 NAME

smppconvert.pl

=head1 SYNOPSIS

smppconvert.pl

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

