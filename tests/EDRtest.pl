#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  EDRtest.pl
#
#        USAGE:  ./EDRtest.pl 
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
#      CREATED:  04.01.2011 16:36:24 EET
#     REVISION:  ---
#===============================================================================

use 5.8.0;
use strict;
use warnings;

use lib '../'; 

use NetSDS::EDR; 

my $edr_type = 'database'; 
my $dsn = 'DBI:mysql:database=mydb;host=192.168.1.53';
my $user = 'netstyle'; 
my $password = ''; 
my $query = 'insert into smppd_events(event_name,src_addr_port,system_id,cmd_id,cmd_status,src,dst,userfield) values (?,?,?,?,?,?,?,?)'; 

my $mapping = { 
    0 => 'event_name',
    1 => 'src_addr_port',
    2 => 'system_id',
    3 => 'cmd_id',
    4 => 'cmd_status',
    5 => 'src',
    6 => 'dst',
    7 => 'userfield'
}; 

my $edr = NetSDS::EDR->new(  type => 'database', dsn => $dsn, user => $user, password => $password, 
	query => $query ); 

$edr->write ( { event_name => 'Program start'} , $mapping ); 
$edr->write ( { event_name => 'Authentication', 
			src_addr_port => '127.0.0.1:1234', 
			system_id => 'rad',
			cmd_id => 0x01, 
			cmd_status => 0x00, 
			Status => 'OK' 
			}, $mapping); 
$edr->write ( { event_name => 'Submit SM', 
			src_addr_port => '127.0.0.1:1234', 
			system_id => 'rad',
			cmd_id => 0x04, 
			cmd_status => 0x00, 
			Status => 'OK',
			src => 'rad',
			dst => '0504139380', 
			}, $mapping); 

# Database test finished.  Rawfile test.
$edr = NetSDS::EDR->new( type => 'rawfile', filename => './events.dat'); 
$edr->write ( { event_name => 'Program start'} , $mapping ); 
$edr->write ( { event_name => 'Authentication', 
			src_addr_port => '127.0.0.1:1234', 
			system_id => 'rad',
			cmd_id => 0x01, 
			cmd_status => 0x00, 
			Status => 'OK' 
			}); 
$edr->write ( { event_name => 'Submit SM', 
			src_addr_port => '127.0.0.1:1234', 
			system_id => 'rad',
			cmd_id => 0x04, 
			cmd_status => 0x00, 
			Status => 'OK',
			src => 'rad',
			dst => '0504139380', 
			}); 

#
$edr = NetSDS::EDR->new( type => 'syslog', prefix => 'EDR'); 
$edr->write ( { event_name => 'Program start'} , $mapping ); 
$edr->write ( { event_name => 'Authentication', 
			src_addr_port => '127.0.0.1:1234', 
			system_id => 'rad',
			cmd_id => 0x01, 
			cmd_status => 0x00, 
			Status => 'OK' 
			}); 
$edr->write ( { event_name => 'Submit SM', 
			src_addr_port => '127.0.0.1:1234', 
			system_id => 'rad',
			cmd_id => 0x04, 
			cmd_status => 0x00, 
			Status => 'OK',
			src => 'rad',
			dst => '0504139380', 
			}); 



1;
#===============================================================================

__END__

=head1 NAME

EDRtest.pl

=head1 SYNOPSIS

EDRtest.pl

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

