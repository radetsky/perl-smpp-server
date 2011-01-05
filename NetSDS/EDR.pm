#===============================================================================
#
#         FILE:  EDR.pm
#
#  DESCRIPTION:  Module for reading/writing Event Details Records
#
#        NOTES:  ---
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#       AUTHOR:  Alex Radetsky (rad), <rad@rad.kiev.ua>
#      COMPANY:  Net.Style
#      CREATED:  28.08.2009 16:43:02 EEST
#     MODIFIED:  03.01.2011
#===============================================================================

=head1 NAME

NetSDS::EDR - read/write Event Details Records

=head1 SYNOPSIS

	use NetSDS::EDR;

	my $edr = NetSDS::EDR->new(
		filename => '/mnt/billing/call-stats.dat',
	);

	...

	$edr->write(
		{
		callerid => '80441234567',
		clip => '89001234567',
		start_time => '2006-12-55 12:21:46',
		end_time => '2008-12-55 12:33:22'
		}
	);

=head1 DESCRIPTION

C<NetSDS::EDR> module implements API for writing EDR (Event Details Record) files
form applications.

EDR itself is set of structured data describing details of some event. Exact
structure depends on event type and so hasn't fixed structure.

In NetSDS EDR data is written to plain text files as JSON structures one row per record.

=cut

package NetSDS::EDR;

use 5.8.0;
use strict;
use warnings;

use JSON;
use Data::Dumper; 
use NetSDS::Util::DateTime;
use base 'NetSDS::Class::Abstract';

use NetSDS::EDR::Database; 
use NetSDS::EDR::Syslog; 
use NetSDS::EDR::Rawfile;  

use version;
our $VERSION = '2.000';

#===============================================================================
#

=head1 CLASS API

=over

=item B<new(%params)> - class constructor

Parameters:

* type - EDR type one of 'database','syslog','rawfile';
* filename - EDR file name for rawfile 
* prefix - 'EDR' for syslog 
* dsn, db-user,db-password, table for database 

Example:

    my $edr = NetSDS::EDR->new(
	    type => 'rawfile',
		filename => '/mnt/stat/ivr.dat',
	);

	my $edr = NetSDS::EDR->new( 
	    type => 'syslog',
		prefix => 'EDR:'
	);

	my $edr = NetSDS::EDR->new( 
	    type => 'database', 
		dsn => 'DBI:mysql:database=mydb;host=192.168.1.53',
		user => 'rad',
		password => 'secret',
	); 

=cut

#-----------------------------------------------------------------------
sub new {

	my ( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	# Create JSON encoder for EDR data processing
	$self->{encoder} = JSON->new();

	# Define engine to use for EDR
	$self->{engine} = undef;

	unless ( defined( $params{type} ) ) {
		return $class->error("Mandatory parameter 'type' is required!");
	}

	if ( $params{type} =~ /database/i ) {
		# Checking for parameters for database engine
		unless ( ( defined( $params{dsn} ) )
			or ( defined( $params{user} ) )
			or ( defined( $params{password} ) ) )
		{
			return $class->error("For database engine parameters is : dsn, user, password, query.");
		}
		$self->{engine} = NetSDS::EDR::Database->new(%params);
	}

	if ( $params{type} =~ /syslog/i ) {
		# Check for prefix
		unless ( defined( $params{prefix} ) ) {
			return $class->error("For syslog please define 'prefix' parameter.");
		}
		$self->{engine} = NetSDS::EDR::Syslog->new( prefix => $params{prefix} );
	}

	if ( $params{type} =~ /rawfile/i ) {
		unless ( defined( $params{filename} ) ) {
			return $class->error("For rawfile please define 'filename' parameter.");
		}
		$self->{engine} = NetSDS::EDR::Rawfile->new( filename => $params{filename} );
	}

	unless ( defined( $self->{engine} ) ) {
		return $class->error("Can't init engine class.");
	}

	return $self;

} ## end sub new

#***********************************************************************

=item B<write($rec1 [,$rec2 [...,$recN]])> - write EDR to inited engine 

Each record writing to one separate string.

Example:

	$edr->write({from => '380441234567', to => '5552222', status => 'busy'});

=cut

#-----------------------------------------------------------------------
sub write {

	#my ( $self, @records, $params ) = @_;

	my $self = shift; 
	my @records = shift; 
	my $params = shift; 

	#warn "write records: " . Dumper (\@records); 
	#warn "write params : " . Dumper ($params); 

	$self->{engine}->write(@records, $params);

}

1;

__END__

=back

=head1 EXAMPLES

See C<samples> directory.

=head1 TODO

* Handle I/O errors when write EDR data.

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=head1 LICENSE

Copyright (C) 2008-2010 Net Style Ltd.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut


