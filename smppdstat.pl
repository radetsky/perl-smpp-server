#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  smppd.pl
#
#        USAGE:  ./smppd.pl
#
#  DESCRIPTION:  NetSDS SMPP Server
#
#      OPTIONS:  ---
# REQUIREMENTS:
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  12.07.2009 15:15:03 UTC
#     REVISION:  ---
#     MODIFIED:  Alex Radetsky (rad), <rad@rad.kiev.ua>
#===============================================================================

use 5.8.0;
use strict;
use warnings;

SMPPdSTAT->run(
	daemon    => undef,
	verbose   => 1,
	has_conf  => 1,
	conf_file => "./smppserver.conf",
);

1;

package SMPPdSTAT;

use 5.8.0;
use strict;
use warnings;

use base qw(NetSDS::App);

use IPC::ShareLite;
use JSON;
use Data::Dumper; 

sub run {

	my ($this) = shift;

	my $share = new IPC::ShareLite(
		-key     => 1987,
		-create  => 'no',
		-destroy => 'no'
	) or die ("Can't access to shared memory with segment 1987: $!\n"); 

    my $list = decode_json ( $share->fetch ); 
    warn Dumper ($list); 

}

1;
#===============================================================================

__END__

=head1 NAME

smppd.pl

=head1 SYNOPSIS

smppd.pl

=head1 DESCRIPTION

FIXME

=head1 EXAMPLES

FIXME

=head1 BUGS

Unknown.

=head1 TODO

Empty.

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>
Alex Radetsky <rad@rad.kiev.ua>


=cut
