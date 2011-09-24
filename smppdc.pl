#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  smppdc.pl
#
#        USAGE:  ./smppdc.pl [ --conf ./smppserver.conf ]
#
#  DESCRIPTION:  NetSDS SMPP Server V2 control tool
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Alex Radetsky (Rad), <rad@rad.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  2.1
#      CREATED:  28.09.2010 23:12:11 EEST
#     REVISION:  001
#     MODIFIED:  September 2011
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

    my ( $this, %params ) = @_;
    $this->mk_accessors('shm');

    my $shm_key = $this->_read_shm_key(); 

    my $share = new IPC::ShareLite(
        -key     => $shm_key,
        -create  => 'no',
        -destroy => 'no'
    ) or die("Can't access to shared memory with segment $shm_key : $!\n");

    $this->shm($share);

} ## end sub start

sub process {
    my ( $this, @params ) = @_;

    my $list      = decode_json( $this->shm->fetch );

    if ( defined( $this->{'kick'} ) ) {
        printf( "Kick system-id: %s\n", $this->{'kick'} );

        foreach my $connect_id ( keys %$list ) {
            if ( $list->{$connect_id}->{'login'} eq $this->{'kick'} ) {
                $list->{$connect_id}->{'kick'} = 1;
                $this->shm->lock;
                $this->shm->store( encode_json($list) );
                $this->shm->unlock;
            }
        }
    }
		
    if ( defined( $this->{'debug'} ) ) {
        printf( "Debug system-id: %s\n", $this->{'debug'} );

        foreach my $connect_id ( keys %$list ) {
            if ( $list->{$connect_id}->{'login'} eq $this->{'debug'} ) {
                $list->{$connect_id}->{'debug'} = 1;
                $this->shm->lock;
                $this->shm->store( encode_json($list) );
                $this->shm->unlock;
            }
        }
    }
	
    if ( defined( $this->{'nodebug'} ) ) {
        printf( "Disable debug system-id: %s\n", $this->{'nodebug'} );

        foreach my $connect_id ( keys %$list ) {
            if ( $list->{$connect_id}->{'login'} eq $this->{'nodebug'} ) {
                $list->{$connect_id}->{'debug'} = 0;
                $this->shm->lock;
                $this->shm->store( encode_json($list) );
                $this->shm->unlock;
            }
        }
    }


    if (   ( defined( $this->{'kick'} ) )
        or ( defined( $this->{'reload'} ) ) )
    {
        $this->_send_usr1();
    }

    printf("Processed.\n");

} ## end sub process

sub _send_usr1 {
    my $this = shift;

    my $pidfilename = 'smppserver';
    if ( defined( $this->{conf}->{'pidfilename'} ) ) {
        $pidfilename = $this->{conf}->{'pidfilename'};
    }
    my $serverpid = `cat /var/run/NetSDS/$pidfilename.pid`;
    chomp($serverpid);

    printf( "smppserver PID: %s\n", $serverpid );

    my $res = kill "USR1" => $serverpid;
    if ( $res <= 0 ) {
        printf("Send SIGUSR1 to smppserver failed: $!\n");
    }
}

# Determine execution parameters from CLI
sub _get_cli_param {

    my ($this) = @_;

    my $conf   = undef;
    my $debug  = undef;
    my $kick   = undef;
    my $reload = undef;
    my $help   = undef; 
		my $nodebug = undef; 


    # Get command line arguments
    GetOptions(
        'conf=s'  => \$conf,
				'debug=s'  => \$debug,
				'nodebug=s' => \$nodebug,
        'kick=s'  => \$kick,
        'reload!' => \$reload,
				'help!'   => \$help, 
    );

	  if ($help) { 
				$this->_usage(); 
		} 

    # Set configuration file name
    if ($conf) {
        $this->{conf_file} = $conf;
    }

    # Set debug mode
    if ( defined $debug ) {
        $this->{'debug'} = $debug;
    }

		if ( defined $nodebug ) { 
				$this->{'nodebug'} = $nodebug; 
		}

    # Set application name
    if ( defined $kick ) {
        $this->{'kick'} = $kick;
    }

    if ( defined $reload ) {
        $this->{'reload'} = $reload;
    }

} ## end sub _get_cli_param

=item B<_read_shm_key> 

 Read SHM key from /var/run/NetSDS/somefile.shm

=cut 

sub _read_shm_key {
    my $this = shift;

    my $filename = '/var/run/NetSDS/smppserver.shm';
    if ( defined( $this->{conf}->{'shm'}->{'file'} ) ) {
        $filename = $this->{conf}->{'shm'}->{'file'};
    }
    open( MYSHM, $filename ) or die $!;
    my $key = <MYSHM>;
    chomp $key;
    $key = $key + 0;
    close MYSHM;
    return $key;
}

sub _usage { 
		my $this = shift; 

		print "Usage: $this->{name} [ --reload | --[no]debug ESME_ID | --kick ESME_ID | --conf CONFIG ]\n"; 
		print " --reload : Send USR1 to smppserver. SMPPD2 will refresh user parameters. \n"; 
		print " --debug  : Enable debug for ESME_ID \n"; 
		print " --conf   : Use alternative configuration file. Default ./smppserver.conf \n"; 
		print " --kick   : Send signal to SMPPD2 to disconnect ESME_ID. \n"; 

		exit();

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

