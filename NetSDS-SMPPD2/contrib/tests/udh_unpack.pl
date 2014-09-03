#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  udh_unpack.pl
#
#        USAGE:  ./udh_unpack.pl 
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
#      CREATED:  07.04.2014 21:44:35 EEST
#     REVISION:  ---
#===============================================================================

use 5.8.0;
use strict;
use warnings;

use Data::Dumper; 
use NetSDS::Util::Convert; 

my $udh = "050003010401"; 
my @bytes = map {hex $_} unpack("(A2)*",$udh) ;  
warn Dumper \@bytes;

warn Dumper sprintf("%02x%02x%02x%02x%02x%02x",0x05, 0x00, 0x03, 0x02, 0x04, 0x03); 




1;
#===============================================================================

__END__

=head1 NAME

udh_unpack.pl

=head1 SYNOPSIS

udh_unpack.pl

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

