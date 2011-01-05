#===============================================================================
#
#         FILE:  Database.pm
#
#  DESCRIPTION:  NetSDS::EDR::Database is the class-engine that have to write EDR info via inserts it to database. 
#
#        NOTES:  ---
#       AUTHOR:  Alex Radetsky (Rad), <rad@rad.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  03.01.2011 21:04:57 EET
#===============================================================================
=head1 NAME

NetSDS::

=head1 SYNOPSIS

	use NetSDS::;

=head1 DESCRIPTION

C<NetSDS> module contains superclass all other classes should be inherited from.

=cut

package NetSDS::EDR::Database;

use 5.8.0;
use strict;
use warnings;

use DBI; 
use JSON; 
use base qw(NetSDS::Class::Abstract);

use Data::Dumper; 

use version; our $VERSION = "0.01";
our @EXPORT_OK = qw();

#===============================================================================
#
=head1 CLASS METHODS

=over

=item B<new([...])> - class constructor

    my $object = NetSDS::SomeClass->new(%options);

=cut

#-----------------------------------------------------------------------
sub new {

	my ( $class, %params ) = @_;

	my $this = $class->SUPER::new();
	$this->{encoder} = JSON->new();

	unless ( defined ( $this->_connect_db($params{dsn},$params{user},$params{password}) ) ) { 
		return $class->error("Can't connect to the database: ".$params{dsn});
	}

	$this->_prepare_query($params{query}); 

	return $this;

};

#***********************************************************************
=head1 OBJECT METHODS

=over

=item B<user(...)> - object method

=cut

#-----------------------------------------------------------------------
__PACKAGE__->mk_accessors('dbh');
__PACKAGE__->mk_accessors('sth');

sub _connect_db {

	my ( $this, $dsn, $user, $password ) = @_;

	if ( !$this->dbh or !$this->dbh->ping) { 
		$this->dbh(DBI->connect_cached ($dsn, $user, $password ) ); 

		if (!$this->dbh) { 
			return undef; 
		}
		return 1; 
	}

	return 1;

};

sub _prepare_query { 
	my ($this, $query) = @_; 

	if (!$this->sth) { 
		$this->sth ( $this->dbh->prepare_cached ($query) ); 
	}

}

sub write { 
	#my ($this, @records, $mapping) = @_; 

	my $this = shift; 
	my @records = shift; 
	my $mapping = shift; 

	# @records = is the array of hashes. 
	# $mapping is the map keynum = key which maps to the insert query 

	my @bind; 
	my $userfield = undef; 

	my $count = keys %$mapping;
	for (my $x = 0; $x < $count; $x++) {
		$bind[$x] = undef;
	}

	foreach my $rec (@records) { 
		foreach my $item ( keys %$rec ) { 
			my $num = $this->_map($item,$mapping); # Get the number of bind parameter  
			unless ( defined ( $num ) ) {
				$userfield->{$item} = $rec->{$item}; # Notfound ? Fine. Add to the userfield.
				next;
			}
			$bind[$num] = $rec->{$item}; 
		}
		my $num_userfield = $this->_map('userfield',$mapping);
		#warn Dumper ($userfield,$num_userfield); 
		if ( ($num_userfield)  and ( defined ($userfield) ) ) { 
			$bind[$num_userfield] = $this->{encoder}->encode($userfield);
		}
	}
	#warn Dumper (\@bind);
	$this->sth->execute(@bind); 
}

sub _map { 
	my ($this, $itemname, $mapping) = @_; 

    foreach my $num ( keys %$mapping ) { 
		if ($mapping->{$num} eq $itemname) { 
			return $num;
		}
	}
    return undef; 
}

1;

__END__

=back

=head1 EXAMPLES


=head1 BUGS

Unknown yet

=head1 SEE ALSO

None

=head1 TODO

None

=head1 AUTHOR

Alex Radetsky <rad@rad.kiev.ua>

=cut


