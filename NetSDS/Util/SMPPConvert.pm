#===============================================================================
#
#         FILE:  SMPPConvert.pm
#
#  DESCRIPTION:  This package contains utils to convert SMS body texts from/to GSM alphabets.
#
#        NOTES:  ---
#       AUTHOR:  Alex Radetsky (Rad), <rad@rad.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  10.01.2011 18:16:11 EET
#===============================================================================

=head1 NAME

NetSDS::

=head1 SYNOPSIS

	use NetSDS::Util::SMPPConvert;

=head1 DESCRIPTION

C<NetSDS> module contains superclass all other classes should be inherited from.

=cut

package NetSDS::Util::SMPPConvert;

use 5.8.0;
use strict;
use warnings;

use base 'Exporter';

use version; our $VERSION = "0.01";
our @EXPORT = qw(
  conv_gsm_utf8
  conv_utf8_gsm
);

use NetSDS::Util::Convert;
use NetSDS::Util::String; 

#===============================================================================
#

=head1 CLASS METHODS

=over

=item B<new([...])> - class constructor

    my $object = NetSDS::SomeClass->new(%options);

=cut

#-----------------------------------------------------------------------
sub conv_gsm_utf8 {
	my $str    = shift;
	my $coding = shift;

	my $dststr = $str;

	if ( $coding == 0 ) {
		$dststr = str_recode( $str, 'gsm0338', 'utf8' );
	}
	if ( $coding == 2 ) {
		$dststr = str_recode( $str, 'ucs2-be', 'utf8' );
	}
	if ( $coding == 3 ) {
		$dststr = str_recode( $str, 'iso-8859-1', 'utf8' );
	}

	return $dststr;

}

sub conv_utf8_gsm {
	my $str    = shift;
	my $coding = shift;

	my $dststr = $str;
	if ( $coding == 0 ) {
		$dststr = str_recode( $str, 'utf8', 'gsm0338' );
	}
	if ( $coding == 2 ) {
		$dststr = str_recode( $str, 'utf8', 'ucs2-be' );
	}
	if ( $coding == 3 ) {
		$dststr = str_recode( $str, 'utf8', 'iso-8859-1' );
	}

	return $dststr;
}

1;

__END__

=back

=head1 EXAMPLES


=head1 BUGS

Unknown yet

=head1 SEE ALSO

None

=head1 TODO

None

=head1 AUTHOR

Alex Radetsky <rad@rad.kiev.ua>

=cut


