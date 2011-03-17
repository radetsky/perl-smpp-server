#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  smppdc.pl
#
#        USAGE:  ./smppdc.pl
#
#  DESCRIPTION:  NetSDS SMPP Server V2 control tool
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Alex Radetsky (Rad), <rad@rad.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  28.09.2010 23:12:11 EEST
#     REVISION:  ---
#===============================================================================

use 5.8.0;
use strict;
use warnings;

smppdc->run(
	daemon    => undef,
	verbose   => 1,
	has_conf  => 1,
	conf_file => "./smppserver.conf",
	infinite  => 0,
);

1;

package smppdc;

use 5.8.0;
use strict;
use warnings;

use base qw(NetSDS::App);

use IPC::ShareLite;
use JSON;
use Data::Dumper;

use Getopt::Long qw(:config auto_version auto_help pass_through);

sub start {

	my ($this,%params) = @_; 

	$this->mk_accessors('shm'); 
	
	my $shmseg = 1987;

	if ( defined( $this->conf->{'shm'}->{'segment'} ) ) {
		$shmseg = $this->conf->{'shm'}->{'segment'};
	}

	my $share = new IPC::ShareLite(
		-key     => $shmseg,
		-create  => 'no',
		-destroy => 'no'
	  )
	  or die("Can't access to shared memory with segment $shmseg : $!\n");

	$this->shm($share);

} ## end sub start

sub process {
	my ( $this, @params ) = @_;

	my $list      = decode_json( $this->shm->fetch );
	my $magic_key = $this->conf->{'shm'}->{'magickey'};

	if ( defined( $this->{'kick'} ) ) {
		printf("Kick system-id: %s\n",$this->{'kick'});  

		foreach my $connect_id ( keys %$list ) {
			if ( $list->{$connect_id}->{'login'} eq $this->{'kick'} ) {
				$list->{$connect_id}->{'kick'} = 1;
				$this->shm->lock;
				$this->shm->store( encode_json($list) );
				$this->shm->unlock;
			}
		}
	}

	if ( ( defined ($this->{'kick'} ) ) or 
		( defined ($this->{'reload'} ) ) ) { 
		$this->_send_usr1(); 
	}

	printf("Processed.\n");

} ## end sub process

sub _send_usr1 { 
	my $this = shift; 

    my $serverpid = `cat /var/run/NetSDS/smppserver.pid`; 
	chomp ($serverpid); 
	
	printf("smppserver PID: %s\n",$serverpid); 

    my $res = kill "USR1"=>$serverpid;
	if ($res <= 0) { 
		printf("Send SIGUSR1 to smppserver failed: $!\n"); 
	}
}

# Determine execution parameters from CLI
sub _get_cli_param {

	my ($this) = @_;

	my $conf  = undef;
	my $debug = undef;
	my $kick  = undef;
    	my $reload = undef; 

	# Get command line arguments
	GetOptions(
		'conf=s' => \$conf,
		'debug!' => \$debug,
		'kick=s' => \$kick,
		'reload!' => \$reload,
	);

	# Set configuration file name
	if ($conf) {
		$this->{conf_file} = $conf;
	}

	# Set debug mode
	if ( defined $debug ) {
		$this->{debug} = $debug;
	}

	# Set application name
	if ( defined $kick ) {
		$this->{'kick'} = $kick;
	}

	if ( defined $reload) { 
		$this->{'reload'} = $reload; 
	}

} ## end sub _get_cli_param

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



1;
#===============================================================================

__END__

=head1 NAME

smppdc.pl

=head1 SYNOPSIS

smppdc.pl

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

