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

use NetSDS::Util::DateTime;

sub run {

	my ($this) = shift;

	my $share = new IPC::ShareLite(
		-key     => 1987,
		-create  => 'no',
		-destroy => 'no'
	  )
	  or die("Can't access to shared memory with segment 1987: $!\n");

	my $list          = decode_json( $share->fetch );
#	warn Dumper($list);

#	my $my_local_data = defined( $this->conf->{'shm'}->{'magickey'} ) ? $this->conf->{'shm'}->{'magickey'} : 'My L0c4l D4t4';
    my $my_local_data = 'My L0c4l D4t4';
#	warn Dumper ($my_local_data);

	# Show start and uptime
	my $start_time             = $list->{$my_local_data}->{'start_timestamp'};
#	warn Dumper ($start_time);

	my $str_start_time = localtime($start_time);
#	warn Dumper ($str_start_time);

	my $timediff               = time() - $start_time;
	my $str_uptime = $this->_uptime($timediff);
	printf("Start time: %s\nUptime: %s\n",$str_start_time,$str_uptime); 

	printf("Connected list: \n");
	printf("-------------+------------+-----------+----------+----------+-----------\n");
	printf("  SYSTEM_ID  |    MODE    | BANDWIDTH |   SENT   | RECEIVED | CONNECTED\n");
	printf("-------------+------------+-----------+----------+----------+-----------\n");
	foreach my $login ( keys %$list) {
		if ($login eq $my_local_data) { next; }

		printf("%13s|%12s|%11s|%10d|%10d|%10d\n",
			$login,
			$list->{$login}->{'mode'},
			$list->{$login}->{'bandwidth'},
			$list->{$login}->{'sent'},
			$list->{$login}->{'received'},
			$list->{$login}->{'already_connected'}); 

	}

} ## end sub run

sub _uptime {
	my ( $this, $timediff ) = @_;

	my $days    = int( $timediff / 86400 );
	my $hours   = int( ( $timediff - ( $days * 86400 ) ) / 3600 );
	my $minutes = int( ( $timediff - ( $days * 86400 ) - ( $hours * 3600 ) ) / 60 );
	my $seconds = $timediff % 60;

	return sprintf(
		"%d days %d hours %d minutes %d seconds\n",
		$days,
		$hours,
		$minutes,
		$seconds
	);

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

