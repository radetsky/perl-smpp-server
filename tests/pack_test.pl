#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  pack_test.pl
#
#        USAGE:  ./pack_test.pl 
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
#      CREATED:  20.11.2010 13:56:56 EET
#     REVISION:  ---
#===============================================================================

use 5.8.0;
use strict;
use warnings;

print pack("c",2);
print "Null terminated string".chr(0); 


1;
#===============================================================================

__END__

=head1 NAME

pack_test.pl

=head1 SYNOPSIS

pack_test.pl

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

