package NetSDS::LWP;

use 5.8.0;
use strict;
use warnings;

=head1 NAME

NetSDS::LWP - wrapper around LWP HTTP client library

=cut

use version; our $VERSION = '1.400';

use base 'NetSDS::Class::Abstract';

use LWP::UserAgent;
use URI::Escape;
use JSON;

=head1 SYNOPSIS

	use NetSDS::LWP;

	my $lwp = NetSDS::LWP->new();

	my $weather = $lwp->get_simple(
		'http://server.com/weather.php',
		city => 'Kiev',
		date => '2009-03-12',
	);

	print "Weather data: " . $weather;


=head1 DESCRIPTION

C<NetSDS::LWP> module implements easy to use API to web services
based on HTTP and HTTPS protocols. 

=cut

#===============================================================================

=head1 CLASS API

=over

=item B<new(%params)> - class constructor

Example:

    my $lwp = NetSDS::LWP->new();

=cut

#-----------------------------------------------------------------------
sub new {

	my ( $class, %params ) = @_;

	my $this = $class->SUPER::new(%params);

	# Initialize LWP user agent
	$this->{_ua} = LWP::UserAgent->new();
	$this->{_ua}->agent("NetSDS/$VERSION");

	return $this;

}

#***********************************************************************

=item B<get_simple($url [, %params])> - simple REST like request

This methods send HTTP GET request to server and return
result as string for further processing.

Example:

	my $weather = $lwp->get_simple(
		'http://server.com/weather.php',
		city => 'Kiev',
		date => '2009-03-12',
	);

	print "Weather data: " . $weather;

=cut

#-----------------------------------------------------------------------
sub get_simple {

	my ( $this, $url, %params ) = @_;

	# Prepare HTTP request parameters for GET request
	my @pairs = map $_ . '=' . uri_escape( $params{$_} ), keys %params;
	$url .= '?' . join '&', @pairs;

	# Prepare and send HTTP request
	my $req = HTTP::Request->new( GET => $url );
	my $res = $this->{_ua}->request($req);

	# Analyze response and return result
	if ( $res->is_success ) {
		return $res->content;
	} else {
		return $this->error( $res->status_line );
	}

} ## end sub get_simple

=item B<get_json($url [, %params])> - retrieve JSON response

This method is quite similar to C<get_simple()> but also expect
JSON encoded response and return it as native Perl structure.

	$res = $lwp->get_json(
		'http://ajax.googleapis.com/ajax/services/language/translate',
		v        => '1.0',
		q        => 'Fall down',
		langpair => 'en|ru',
	);

	print Dumper($res);

=cut

sub get_json {

	my ( $this, $url, %params ) = @_;

	if ( my $res = $this->get_simple( $url, %params ) ) {
		return from_json($res);
	} else {
		return undef;
	}

}
1;

__END__

=back

=head1 EXAMPLES

See C<samples> directory.

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


