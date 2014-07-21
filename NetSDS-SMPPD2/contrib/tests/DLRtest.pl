#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  DLRtest.pl
#
#        USAGE:  ./DLRTest.pl
#
#  DESCRIPTION:  Test DLR cases for smppserver v 2.x
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Alex Radetsky (Rad), <rad@rad.kiev.ua>
#      COMPANY:  PearlPBX
#      VERSION:  2.0
#      CREATED:  08.12.13
#     REVISION:  001
#===============================================================================

use 5.8.0;
use strict;
use warnings;

use Data::Dumper;
use Time::HiRes qw(gettimeofday tv_interval);

use DBI;
use JSON;

use NetSDS::Util::Convert;

my $dsn      = 'DBI:mysql:database=smpp;host=localhost';
my $user     = 'smpp';
my $password = 'smpp234';

my $dbh = DBI->connect_cached( $dsn, $user, $password );
unless ( defined($dbh) ) {
	die "fail: can't connect to database. DSN: '$dsn'\n";
}

printf("Connected to database.\n"); 

while (1) { 
	my $msgs = $dbh->selectall_hashref("select * from messages where msg_type='MT' order by id","id"); 
	foreach my $dbid ( keys %{$msgs} ) { 
		create_dlr($msgs->{$dbid});
		delete_dbid($dbid); 
	}
	sleep (3); 
}

sub create_dlr { 
	my $msg = shift; 
	my $tlv = { message_state => 2, receipted_message_id => $msg->{'message_id'} };
	my $extra = to_json( $tlv, { ascii => 1, pretty => 1 } );
	my $dlr   = sprintf("id:%s sub:001 dlvrd:001 submit date:%s done date:%s stat:%s err:0 Text:%s", 
		substr($msg->{'message_id'},0,10),
		submit_date($msg->{'received'}), 
		submit_date($msg->{'received'}), 
		rand_stat(), 
		"DLR Test."); 

	printf("[DLR] %s\n",$dlr); 

	my $sth = $dbh->prepare_cached("insert into messages ( msg_type, esme_id, src_addr, dst_addr, body, coding, udh, mwi, mclass, message_id, validity, deferred, registered_delivery, service_type, extra ) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,? ) ");
	$sth->execute( 'DLR', $msg->{'esme_id'}, $msg->{'dst_addr'}, $msg->{'src_addr'}, $dlr, 0, undef, undef, 4, $msg->{'message_id'}, 1440, undef, undef, undef, $extra );
}

sub submit_date { 
	my $str = shift; 
	my $y = substr($str,0,4); 
	my $m = substr($str,5,2); 
	my $d = substr($str,8,2); 
	my $h = substr($str,11,2); 
	my $mm = substr($str,14,2); 

	return sprintf("%s%s%s%s%s",$y,$m,$d,$h,$mm); 
}

sub rand_stat { 
	my $i = int(rand(2)); 
	if ($i < 1 ) { 
		return 'DELIVRD'; 
	} else { 
		return 'UNDELIV'; 
	}
}

sub delete_dbid { 
	my $id = shift; 
	printf("[DEL] $id\n"); 
	$dbh->do("delete from messages where id=$id"); 
}

1;
#===============================================================================

__END__

=head1 NAME

smppsvrtst.pl

=head1 SYNOPSIS

smppsvrtst.pl

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

