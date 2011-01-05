#===============================================================================
#
#         FILE:  Rawfile.pm
#
#  DESCRIPTION:  NetSDS::EDR::Rawfile is the class-engine to NetSDS::EDR that have to write some events
#  in this case to raw text file.
#
#        NOTES:  ---
#       AUTHOR:  Alex Radetsky (Rad), <rad@rad.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  03.01.2011 19:37:32 EET
#===============================================================================

=head1 NAME

NetSDS::EDR::Rawfile

=head1 SYNOPSIS

	perldoc NetSDS::EDR for any information. This class not for direct use! 

=head1 DESCRIPTION


=cut

package NetSDS::EDR::Rawfile;

use 5.8.0;
use strict;
use warnings;

use base qw(NetSDS::Class::Abstract);

use JSON;
use Data::Dumper; 
use NetSDS::Util::DateTime;

use version; our $VERSION = "0.01";
our @EXPORT_OK = qw();

#===============================================================================
#

=head1 CLASS METHODS

=over

=item B<new([...])> - class constructor

    my $object = NetSDS::SomeClass->new(%options);

=cut

#-----------------------------------------------------------------------
sub new {
	my ( $class, %params ) = @_;

	my $this = $class->SUPER::new();

	# Create JSON encoder for EDR data processing
	$this->{encoder} = JSON->new();

	$this->{filename} = $params{filename};

	return $this;

}

#***********************************************************************

=head1 OBJECT METHODS

=over

=item B<user(...)> - object method

=cut

#-----------------------------------------------------------------------
#__PACKAGE__->mk_accessors('user');

sub write {

	my $self = shift; 
	my @records = shift; 
	my $params = @_; 

	open EDRF, ">>$self->{filename}";

	# Write records - one record per line
	
	foreach my $rec (@records) {
		$rec->{'timestamp'} = date_now();
		my $edr_json = $self->{encoder}->encode($rec);
		print EDRF "$edr_json\n";
	}

	close EDRF;

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


