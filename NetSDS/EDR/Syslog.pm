#===============================================================================
#
#         FILE:  Syslog.pm
#
#  DESCRIPTION:  NetSDS::EDR::Syslog is class-engine for NetSDS::EDR, it have to put EDR via syslog with prefix,
#  which must be defined as parameter to constructor.
#
#        NOTES:  ---
#       AUTHOR:  Alex Radetsky (Rad), <rad@rad.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  03.01.2011 20:50:56 EET
#===============================================================================

=head1 NAME

NetSDS::EDR::Syslog

=head1 SYNOPSIS

	perldoc NetSDS::EDR for any information. This class not for direct use! 

=head1 DESCRIPTION

C<NetSDS> module contains superclass all other classes should be inherited from.

=cut

package NetSDS::EDR::Syslog;

use 5.8.0;
use strict;
use warnings;

use base qw(NetSDS::Class::Abstract);

use JSON;
use Encode; 
use NetSDS::Util::DateTime;
use NetSDS::Logger; 

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

	$this->{encoder} = JSON->new()->utf8(1);

	$this->{logger} = NetSDS::Logger->new( name => $params{prefix} );

	return $this;

}

#***********************************************************************

=head1 OBJECT METHODS

=over

=item B<user(...)> - object method

=cut

#-----------------------------------------------------------------------

sub write {

	my $this = shift; 
	my @records = shift; 
	my $params = @_; 

	foreach my $rec (@records) {

		my $edr_json = $this->{encoder}->encode($rec);
		$this->{logger}->log( "info", $edr_json );

	}
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


