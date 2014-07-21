#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  send_json.pl
#
#        USAGE:  ./send_json.pl
#
#  DESCRIPTION:  Read messages received by SMPP and send it in JSON format to HTTP in batch mode
#
#       AUTHOR:  Alex Radetsky (Rad), <rad@pearlpbx.com>
#      COMPANY:  PearlPBX
#      VERSION:  1.0
#      CREATED:  01.04.2014
#     REVISION:  001
#===============================================================================

use 5.8.0;
use strict;
use warnings;

my $dsn      = 'DBI:mysql:database=smppserver;host=localhost';
my $user     = 'smppserver';
my $password = 'alexradetsky';
#my $senha    = 'smpp_179ecc508e2000c99f2d0fecb336ebcc'; # platform user password taken from SQL 
my $link     = 'http://186.226.85.40/smsmachine/receberMultiplos.php';
my $chains = undef; 

MyApp->run (
	has_conf => undef, 
	daemon => undef, 
	verbose => 1, 
	use_pidfile => 1
	); 

1; 

package MyApp; 

use base 'NetSDS::App'; 
use Data::Dumper;
use Time::HiRes qw(gettimeofday tv_interval);

use DBI;
use JSON;

use NetSDS::Util::Convert;
use Sys::Hostname; 
use LWP::UserAgent; 
use HTTP::Request; 

sub start { 
	my ($this) = @_; 

	$this->speak("dsn=$dsn\n"); 

	my $dbh = DBI->connect_cached( $dsn, $user, $password, {RaiseError => 1, AutoCommit =>1, mysql_auto_reconnect=>1 } );
	unless ( defined($dbh) ) {
		die "fail: can't connect to database. DSN: '$dsn'\n";
	}
	$this->{'dbh'} = $dbh; 
}

sub process { 
	my ($this) = @_;  

	my $nosuchmessages = 0; 
	my $active_users = $this->_get_active_users(); 
	unless ( defined ( $active_users ) ) { 
		$this->log('info','[ CORE ] There is no active users. Sleeping 30 seconds.'); 
		sleep (30); 
		return undef; 
	}
	foreach my $esme_id ( keys %{ $active_users } ) {
		my $sql = sprintf("select * from messages where esme_id=%d and msg_type=\'MT\' order by id", $esme_id); 
		my $msgs = $this->{'dbh'}->selectall_hashref($sql,"id"); 
		# warn Dumper ($msgs);
		my @json_encoded_messages = (); 
		foreach my $dbid ( keys %{$msgs} ) { 
			my $ssid = hostname . '-' . myrand(); 
			my %json_message = $this->_create_json_message($msgs->{$dbid}, $ssid);
			unless ( %json_message ) { next; } 
			my @a = (\%json_message);
			push @json_encoded_messages, @a; 
			#delete_dbid($dbid); 
		}
		unless ( @json_encoded_messages ) { 
			$this->log('info', sprintf("[ CORE ] There is no messages for esme_id=%d; next. \n", $esme_id)); 
			$nosuchmessages = 1; 
		} else { 
			$nosuchmessages = 0;
			my $senha = $active_users->{$esme_id}->{'platform_password'};
			my %session = ( senha => $senha, simples => 0, mensagens => \@json_encoded_messages);
			my @a = (\%session);
			my $objJSON = JSON->new->canonical; 
			my $json = $objJSON->encode(\@a); 
			my $result = $this->_send_json ($json, $link );  
			warn Dumper $result;
			if ($result =~ /Numero Inseridos:(\d+)/ ) {
				$this->log("info",sprintf("[ HTTP ] %d messages sent.", $1));
				warn sprintf("[ HTTP ] %d messages sent.", $1);
			} else {
				$this->log("error", "[ HTTP ] Error occurred while sending messages. "); 
				warn "[ HTTP ] Error occurred while sending messages. ";
			}
			#print "send json to $link\n"; 
		}
	}
	if ( $nosuchmessages > 0) { 
		$this->log('info','[ CORE ] There is no messages for all active users. Sleeping 10 seconds.'); 
		sleep (10); 
	} 
}

sub _send_json { 
	my ( $this, $json, $link ) = @_; 
	
	$this->log('info',sprintf("[ JSON ] %s", $json )); 

	my $ua = LWP::UserAgent->new(); 
	my $req = HTTP::Request->new(POST => $link); 
	$req->content_type('application/json');
	$req->content($json); 

	print $req->as_string; 
	my $result = $ua->request($req); 
	$this->log('info',sprintf("[ RESULT ] %s\n", $result->as_string));
	# printf("[ RESULT ] %s\n", $result->as_string);
	return $result->as_string;
}

sub _create_json_message { 
	my ($this, $msg, $ssid ) = @_; 
	my $dst_addr = $msg->{'dst_addr'}; 
	my $text = $msg->{'body'}; # It's already translated to utf-8 in $smppserver->plugindb->_convert_mt() 
	my $udh = $msg->{'udh'}; # 050003010401 format. 
	
	unless ( defined ( $udh ) ) {
		$this->_delete_dbid($msg->{'id'}); 
		return my %msg = ( 
			destino => $dst_addr, 
			msg => $text,
			ssid => $ssid, 
			senha_mini => $ssid # same as ssid as pointed in example php code 
		);

	} # end unless defined ( $udh ) 
	
	return $this->_part_of_message ( $msg, $ssid ); 
} 

sub _part_of_message { 
	my ($this, $msg, $ssid ) = @_; 
	my $udh = $msg->{'udh'}; 

	my ( $udhl, $fake, $three, $chain_id, $chain_parts, $part_id ) = map { hex $_ } unpack ("(A2)*",$udh) ;
	my $msg_in_chains = { 
		dst_addr => $msg->{'dst_addr'}, 
		msg => $msg->{'body'},
		ssid => $ssid, 
		senha_mini => $ssid,
		chain_id => $chain_id, 
		chain_parts => $chain_parts, 
		part_id => $part_id 
	}; 
	#warn Dumper ($msg_in_chains);
	$chains->{$udh} = $msg_in_chains; 
	#warn Dumper ($chains);
	$this->_delete_dbid($msg->{'id'}); 

	return $this->_concatenated_message(); 
} 

sub _concatenated_message { 
	  my ($this) = @_; 
		
BEG1: foreach my $udh ( keys %{$chains} ) { 
		my $msg = $chains->{$udh}; 
		next unless ( $msg->{'part_id'} == 1 ); # Находим первую часть 
		warn "Found 1st part of $udh"; 
		my $chain = $msg->{'chain_id'}; 
		my $chain_parts = $msg->{'chain_parts'}; 
		my $text = $msg->{'msg'}; 
		my $dst = $msg->{'dst_addr'}; 
		my $ssid = $msg->{'ssid'}; 
		my $senha_mini = $msg->{'senha_mini'};

		$this->log('info',sprintf ("[PART] [1 of %d] UDH = %s\n",$chain_parts, $udh));  
		
		for (my $i = 2; $i <= $chain_parts; $i++ ) { 
			my $key = uc ( sprintf("%02x%02x%02x%02x%02x%02x",0x05, 0x00, 0x03, $chain, $chain_parts, $i) ); 
			warn "Search UDH: " . Dumper $key; 
			warn Dumper $chains; 
			unless ( defined ( $chains->{$key} ) ) { next BEG1; }
			warn "Found.";
			$this->log(sprintf("[PART] [%d of %d] UDH = %s\n",$i, $chain_parts, $udh)); 
			$text .= $chains->{$key}->{'msg'}; 
		}
		
		for (my $i = 1; $i <= $chain_parts; $i++ ) { 
			my $key = uc ( sprintf("%02x%02x%02x%02x%02x%02x",0x05, 0x00, 0x03, $chain, $chain_parts, $i) );
			$this->log('info',sprintf("[MEMDEL] $key\n")); 
			delete $chains->{$key}; 
		} # Чистим за собой 

		$this->log('info',sprintf("[CONCATENATED] MSISDN=%s Text=%s\n",$dst,$text)); 
	
		return my %msg = ( 
			destino => $dst,
			msg => $text, 
			ssid => $ssid, 
			senha_mini => $senha_mini
		); 
		
	}
	return my %empty_hash = ( );   
	
}


sub _delete_dbid { 
	my ($this,$id) = @_; 
	$this->log('info',sprintf("[DEL] $id\n")); 
	$this->{'dbh'}->do("delete from messages where id=$id"); 
}

sub _get_active_users { 
	my ($this) = @_; 
	my $select = $this->{'dbh'}->selectall_hashref("select * from auth_table where active=1","esme_id");
	unless ( keys %{ $select } ) { return undef; } 
	return $select; 
} 

sub myrand {
	my @chars = ("0".."9");
	my $string;
	$string .= $chars[rand @chars] for 1..10;
	return $string;

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

