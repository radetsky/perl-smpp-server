#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  encoding_list.pl
#
#        USAGE:  ./encoding_list.pl 
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
#      CREATED:  28.12.2010 09:10:30 EET
#     REVISION:  ---
#===============================================================================

use 5.8.0;
use strict;
use warnings;

use Encode; 
use Data::Dumper; 

print Dumper (Encode->encodings(":all")); 


1;
#===============================================================================

__END__

=head1 NAME

encoding_list.pl

=head1 SYNOPSIS

encoding_list.pl

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

