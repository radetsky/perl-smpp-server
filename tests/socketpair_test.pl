#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  socketpair_test.pl
#
#        USAGE:  ./socketpair_test.pl
#
#  DESCRIPTION:
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Alex Radetsky (Rad), <rad@rad.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  12.01.2011 23:33:34 EET
#     REVISION:  ---
#===============================================================================

use 5.8.0;
use strict;
use warnings;

use lib '../';

use JSON;
use NetSDS::Util::Convert;
use NetSDS::Util::String;

use Benchmark ':hireswallclock';

use Socket;
use IO::Handle;

my $count = $ARGV[0];
unless ( defined($count) ) {
	die "Usage: <count>\n";
}

my $child; 

socketpair( $child, PARENT, AF_UNIX, SOCK_STREAM, PF_UNSPEC );
$child->autoflush();
PARENT->autoflush();


my $pid = undef;

if ( $pid = fork() ) {
	close PARENT;

	my $t1 = new Benchmark; 

	for ( my $x = 0 ; $x < $count ; $x++ ) {
		my $t3 = new Benchmark; 
		my $msg = undef;

		$msg->{'text'}   = 'blablablablablablablablabka';
		$msg->{'coding'} = 2;
		$msg->{'from'}   = '0504139380';
		$msg->{'to'}     = '0672206770';
		$msg->{'subject'} = 'Am I software developer?';

		my $json_text = to_json( $msg, { ascii => 1, pretty => 1 } );
		my $text64    = conv_str_base64($json_text) . "\n";

		print $child $text64;
		print $text64;

		my $line = <$child>;
		chomp $line;
		print $line . "\n";
		my $t4 = new Benchmark; 

		warn "Single item time: " . timestr ( timediff ( $t4, $t3 ) , 'all' );  

	} ## end for ( my $x = 0 ; $x < ...

	my $t2 = new Benchmark; 
	warn "Total: " . timestr ( timediff ($t2, $t1) , 'all' ); 

	close CHILD;
	waitpid( $pid, 0 );

} ## end if ( $pid = fork() )

else {

	die "Can't fork: $!" unless defined $pid;
	close CHILD;
	for ( my $x = 0 ; $x < $count ; $x++ ) {
		my $t1 = new Benchmark; 
		my $line = <PARENT>;
		my $t2 = new Benchmark;
		warn "Receive from socketpair: " . timestr ( timediff ($t2, $t1) , 'all'); 
		chomp $line;

		print "Child received: $line\n";
		print PARENT "OK\n";

	}
	close PARENT;
	exit;
}

1;
#===============================================================================

__END__

=head1 NAME

socketpair_test.pl

=head1 SYNOPSIS

socketpair_test.pl

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

