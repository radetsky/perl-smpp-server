#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  smppdstat.pl
#
#        USAGE:  ./smppdstat.pl [ --conf someother.conf ]
#
#  DESCRIPTION:  NetSDS SMPP Server V2 stat tool
#
#      OPTIONS:  ---
# REQUIREMENTS:
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Alex Radetsky <rad@rad.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  2.1
#      CREATED:  September 2010 
#     REVISION:  001
#     MODIFIED:  September 2011
#===============================================================================

use 5.8.0;
use strict;
use warnings;

SMPPdSTAT->run(
	daemon    => undef,
	verbose   => 1,
	has_conf  => 1,
	conf_file => "./smppserver.conf",
  infinite  => undef, 
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

sub process {

	my $this = shift;

  my $shm_key = $this->_read_shm_key(); 

	my $share = new IPC::ShareLite(
		-key     => $shm_key,
		-create  => 'no',
		-destroy => 'no'
	  )
	  or die("Can't access to shared memory with segment $shm_key: $!\n");

	my $list          = decode_json( $share->fetch );

	my $my_local_data = defined( $this->conf->{'shm'}->{'magickey'} ) ? $this->conf->{'shm'}->{'magickey'} : 'My L0c4l D4t4';

	# Show start and uptime

  my $start_time             = $list->{$my_local_data}->{'start_timestamp'};
	my $str_start_time = localtime($start_time);

	my $timediff               = time() - $start_time;
	my $str_uptime = $this->_uptime($timediff);
	printf("Start time: %s\nUptime: %s\n",$str_start_time,$str_uptime); 

	printf("Connected list: \n");
	printf("--------------------+-------------+------------+------+-------+-------+------\n");
	printf("  CONNECT SRC       |  SYSTEM_ID  |    MODE    | BAND | SENT  | RCVD  | CONN \n");
	printf("--------------------+-------------+------------+------+-------+-------+------\n");
	foreach my $connect_id ( keys %$list) {
		if ($connect_id eq $my_local_data) { next; }

		printf("%20s|%13s|%12s|%6s|%7d|%7d|%6d\n",
			$connect_id,
			$list->{$connect_id}->{'login'},
			$list->{$connect_id}->{'mode'},
			$list->{$connect_id}->{'bandwidth'},
			$list->{$connect_id}->{'sent'},
			$list->{$connect_id}->{'received'},
			$list->{$connect_id}->{'already_connected'}); 

	}

} ## end sub run

=item B<_read_shm_key> 

 Read SHM key from /var/run/NetSDS/somefile.shm

=cut 

sub _read_shm_key { 
		my $this = shift; 

		my $filename = '/var/run/NetSDS/smppserver.shm'; 
	  if ( defined ( $this->{conf}->{'shm'}->{'file'} ) ) { 
			$filename = $this->{conf}->{'shm'}->{'file'}; 
		} 
	  open (MYSHM, $filename) or die $!; 
		my $key = <MYSHM>;
		chomp $key; 
		$key = $key + 0; 
		close MYSHM; 
		return $key; 
}

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

Alex Radetsky <rad@rad.kiev.ua>


=cut

