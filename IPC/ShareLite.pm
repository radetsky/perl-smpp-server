package IPC::ShareLite;

use strict;
use warnings;
use Carp;

=head1 NAME

IPC::ShareLite - Lightweight interface to shared memory 

=head1 VERSION

This document describes IPC::ShareLite version 0.17

=cut

use vars qw(
 $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD
);

use subs qw(
 IPC_CREAT IPC_EXCL IPC_RMID IPC_STAT IPC_PRIVATE GETVAL SETVAL GETALL
 SEM_UNDO LOCK_EX LOCK_SH LOCK_UN LOCK_NB
);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw( Exporter DynaLoader );

@EXPORT = qw( );

@EXPORT_OK = qw(
 IPC_CREAT IPC_EXCL IPC_RMID IPC_STATE IPC_PRIVATE GETVAL SETVAL GETALL
 SEM_UNDO LOCK_EX LOCK_SH LOCK_UN LOCK_NB
);

%EXPORT_TAGS = (
  all => [
    qw(
     IPC_CREAT IPC_EXCL IPC_RMID IPC_PRIVATE LOCK_EX LOCK_SH LOCK_UN
     LOCK_NB
     )
  ],
  lock  => [qw( LOCK_EX LOCK_SH LOCK_UN LOCK_NB )],
  flock => [qw( LOCK_EX LOCK_SH LOCK_UN LOCK_NB )],
);

Exporter::export_ok_tags( 'all', 'lock', 'flock' );

$VERSION = '0.17';

=head1 SYNOPSIS

    use IPC::ShareLite;

    my $share = IPC::ShareLite->new(
        -key     => 1971,
        -create  => 'yes',
        -destroy => 'no'
    ) or die $!;

    $share->store( "This is stored in shared memory" );
    my $str = $share->fetch;

=head1 DESCRIPTION

IPC::ShareLite provides a simple interface to shared memory, allowing
data to be efficiently communicated between processes. Your operating
system must support SysV IPC (shared memory and semaphores) in order to
use this module.

IPC::ShareLite provides an abstraction of the shared memory and
semaphore facilities of SysV IPC, allowing the storage of arbitrarily
large data; the module automatically acquires and removes shared memory
segments as needed. Storage and retrieval of data is atomic, and locking
functions are provided for higher-level synchronization.

In many respects, this module is similar to IPC::Shareable. However,
IPC::ShareLite does not provide a tied interface, does not 
(automatically) allow the storage of variables, and is written in C
for additional speed.

Construct an IPC::ShareLite object by calling its constructor:

    my $share = IPC::ShareLite->new(
        -key     => 1971,
        -create  => 'yes',
        -destroy => 'no'
    ) or die $!;

Once an instance has been created, data can be written to shared memory
by calling the store() method:

	$share->store("This is going in shared memory");

Retrieve the data by calling the fetch() method:

	my $str = $share->fetch();

The store() and fetch() methods are atomic; any processes attempting
to read or write to the memory are blocked until these calls finish.
However, in certain situations, you'll want to perform multiple
operations atomically.  Advisory locking methods are available for 
this purpose.

An exclusive lock is obtained by calling the lock() method:

	$share->lock();

Happily, the lock() method also accepts all of the flags recognized
by the flock() system call.  So, for example, you can obtain a
shared lock like this:

	$share->lock( LOCK_SH );

Or, you can make either type of lock non-blocking:

	$share->lock( LOCK_EX|LOCK_NB );

Release the lock by calling the unlock() method:

	$share->unlock;

=head1 METHODS

=head2 C<< new($key, $create, $destroy, $exclusive, $mode, $flags, $size) >>

This is the constructor for IPC::ShareLite.  It accepts both 
the positional and named parameter calling styles.

C<$key> is an integer value used to associate data between processes.
All processes wishing to communicate should use the same $key value.
$key may also be specified as a four character string, in which case
it will be converted to an integer value automatically.  If $key
is undefined, the shared memory will not be accessible from other
processes.

C<$create> specifies whether the shared memory segment should be
created if it does not already exist.  Acceptable values are
1, 'yes', 0, or 'no'.

C<$destroy> indicates whether the shared memory segments and semaphores
should be removed from the system once the object is destroyed.
Acceptable values are 1, 'yes', 0, or 'no'.

If C<$exclusive> is true, instantiation will fail if the shared memory
segment already exists. Acceptable values are 1, 'yes', 0, or 'no'.

C<$mode> specifies the permissions for the shared memory and semaphores.
The default value is 0666.

C<$flags> specifies the exact shared memory and semaphore flags to
use. The constants IPC_CREAT, IPC_EXCL, and IPC_PRIVATE are available
for import.

C<$size> specifies the shared memory segment size, in bytes. The default
size is 65,536 bytes, which is fairly portable. Linux, as an example,
supports segment sizes of 4 megabytes.

The constructor croaks on error.

=cut

sub new {
  my $class = shift;
  my $self = bless {}, ref $class || $class;

  my $args = $class->_rearrange_args(
    [
      qw( key create destroy exclusive mode
       flags size glue )
    ],
    \@_
  );

  $self->_initialize( $args );

  return $self;
}

sub _8bit_clean {
  my ( $self, $str ) = @_;
  croak "$str is not 8-bit clean"
   if grep { $_ > 255 } map ord, split //, $str;
}

sub _initialize {
  my $self = shift;
  my $args = shift;

  for ( qw( create exclusive destroy ) ) {
    $args->{$_} = 0
     if defined $args->{$_} and lc $args->{$_} eq 'no';
  }

  # Allow glue as a synonym for key
  $self->{key} = $args->{key} || $args->{glue} || IPC_PRIVATE;

  # Allow a four character string as the key
  unless ( $self->{key} =~ /^\d+$/ ) {
    croak "Key must be a number or four character string"
     if length $self->{key} > 4;
    $self->_8bit_clean( $self->{key} );
    $self->{key} = unpack( 'i', pack( 'A4', $self->{key} ) );
  }

  $self->{create} = ( $args->{create} ? IPC_CREAT : 0 );

  $self->{exclusive} = (
    $args->{exclusive}
    ? IPC_EXCL | IPC_CREAT
    : 0
  );

  $self->{destroy} = ( $args->{destroy} ? 1 : 0 );

  $self->{flags} = $args->{flags} || 0;
  $self->{mode}  = $args->{mode}  || 0666 unless $args->{flags};
  $self->{size}  = $args->{size}  || 0;

  $self->{flags} = $self->{flags} | $self->{exclusive} | $self->{create}
   | $self->{mode};

  $self->{share}
   = new_share( $self->{key}, $self->{size}, $self->{flags} )
   or croak "Failed to create share";

  return 1;
}

sub _rearrange_args {
  my ( $self, $names, $params ) = @_;
  my ( %hash, %names );

  return \%hash unless ( @$params );

  unless ( $params->[0] =~ /^-/ ) {
    croak "unexpected number of parameters"
     unless ( @$names == @$params );
    $hash{@$names} = @$params;
    return \%hash;
  }

  %names = map { $_ => 1 } @$names;

  while ( @$params ) {
    my $param = lc substr( shift @$params, 1 );
    exists $names{$param} or croak "unexpected parameter '-$param'";
    $hash{$param} = shift @$params;
  }

  return \%hash;
}

=head2 C<< store( $scalar ) >>

This method stores C<$scalar> into shared memory.  C<$scalar> may be
arbitrarily long.  Shared memory segments are acquired and
released automatically as the data length changes.
The only limits on the amount of data are the system-wide
limits on shared memory pages (SHMALL) and segments (SHMMNI)
as compiled into the kernel. 

The method raises an exception on error.

Note that unlike L<IPC::Shareable>, this module does not automatically
allow references to be stored. Serializing all data is expensive, and is
not always necessary. If you need to store a reference, you should employ
the L<Storable> module yourself. For example:

    use Storable qw( freeze thaw );
    ...
	$hash = { red => 1, white => 1, blue => 1 };
    $share->store( freeze( $hash ) );
    ...
    $hash = thaw( $share->fetch );

=cut

sub store {
  my $self = shift;

  if ( write_share( $self->{share}, $_[0], length $_[0] ) < 0 ) {
    croak "IPC::ShareLite store() error: $!";
  }
  return 1;
}

=head2 C<< fetch >>

This method returns the data that was previously stored in
shared memory.  The empty string is returned if no data was
previously stored.

The method raises an exception on error.

=cut

sub fetch {
  my $self = shift;

  my $str = read_share( $self->{share} );
  defined $str or croak "IPC::ShareLite fetch() error: $!";
  return $str;
}

=head2 C<< lock( $type ) >>

Obtains a lock on the shared memory.  $type specifies the type
of lock to acquire.  If $type is not specified, an exclusive
read/write lock is obtained.  Acceptable values for $type are
the same as for the flock() system call.  The method returns
true on success, and undef on error.  For non-blocking calls
(see below), the method returns 0 if it would have blocked.

Obtain an exclusive lock like this:
	
	$share->lock( LOCK_EX ); # same as default 

Only one process can hold an exclusive lock on the shared memory at
a given time.

Obtain a shared lock this this:

	$share->lock( LOCK_SH );

Multiple processes can hold a shared lock at a given time.  If a process
attempts to obtain an exclusive lock while one or more processes hold
shared locks, it will be blocked until they have all finished.

Either of the locks may be specified as non-blocking:

	$share->lock( LOCK_EX|LOCK_NB );
        $share->lock( LOCK_SH|LOCK_NB );
  
A non-blocking lock request will return 0 if it would have had to
wait to obtain the lock.    

Note that these locks are advisory (just like flock), meaning that
all cooperating processes must coordinate their accesses to shared memory
using these calls in order for locking to work.  See the flock() call for 
details.

Locks are inherited through forks, which means that two processes actually
can possess an exclusive lock at the same time.  Don't do that.

The constants LOCK_EX, LOCK_SH, LOCK_NB, and LOCK_UN are available
for import:

	use IPC::ShareLite qw( :lock );

Or, just use the flock constants available in the Fcntl module.

=cut

sub lock {
  my $self = shift;

  my $response = sharelite_lock( $self->{share}, shift() );
  return undef if ( $response == -1 );
  return 0 if ( $response == 1 );    # operation failed due to LOCK_NB
  return 1;
}

=head2 C<< unlock >>

Releases any locks.  This is actually equivalent to:

	$share->lock( LOCK_UN );

The method returns true on success and undef on error.

=cut

sub unlock {
  my $self = shift;

  return undef if ( sharelite_unlock( $self->{share} ) < 0 );
  return 1;
}

# DEPRECATED -- Use lock() and unlock() instead.
sub shlock   { shift->lock( @_ ) }
sub shunlock { shift->unlock( @_ ) }

=head2 C<< version >>

Each share has a version number that incrementents monotonically for
each write to the share. When the share is initally created its version
number will be 1.

    my $num_writes = $share->version;

=cut

sub version { sharelite_version( shift->{share} ) }

=head2 C<< key >>

Get a share's key.

    my $key = $share->key;

=cut

sub key { shift->{key} }

=head2 C<< create >>

Get a share's create flag.

=cut

sub create { shift->{create} }

=head2 C<< exclusive >>

Get a share's exclusive flag.

=cut

sub exclusive { shift->{exclusive} }

=head2 C<< flags >>

Get a share's flag.

=cut

sub flags { shift->{flags} }

=head2 C<< mode >>

Get a share's mode.

=cut

sub mode { shift->{mode} }

=head2 C<< size >>

Get a share's segment size.

=cut

sub size { shift->{size} }

=head2 C<< num_segments >>

Get the number of segments in a share. The memory usage of a share can
be approximated like this:

    my $usage = $share->size * $share->num_segments;

C<$usage> will be the memory usage rounded up to the next segment
boundary.

=cut

sub num_segments {
  my $self = shift;

  my $count = sharelite_num_segments( $self->{share} );
  return undef if $count < 0;
  return $count;
}

=head2 C<< destroy >>

Get or set the share's destroy flag.

=cut

sub destroy {
  my $self = shift;
  $self->{destroy} = shift if @_;
  return $self->{destroy};
}

sub DESTROY {
  my $self = shift;

  destroy_share( $self->{share}, $self->{destroy} )
   if $self->{share};
}

sub AUTOLOAD {
  # This AUTOLOAD is used to 'autoload' constants from the constant()
  # XS function.  If a constant is not found then control is passed
  # to the AUTOLOAD in AutoLoader.

  my $constname;
  ( $constname = $AUTOLOAD ) =~ s/.*:://;
  my $val = constant( $constname, @_ ? $_[0] : 0 );
  if ( $! != 0 ) {
    if ( $! =~ /Invalid/ ) {
      $AutoLoader::AUTOLOAD = $AUTOLOAD;
      goto &AutoLoader::AUTOLOAD;
    }
    else {
      croak "Your vendor has not defined ShareLite macro $constname";
    }
  }
  eval "sub $AUTOLOAD { $val }";
  goto &$AUTOLOAD;
}

bootstrap IPC::ShareLite $VERSION;

1;

__END__

=head1 PERFORMANCE

For a rough idea of the performance you can expect, here are some
benchmarks.  The tests were performed using the Benchmark module
on a Cyrix PR166+ running RedHat Linux 5.2 with the 2.0.36 kernel,
perl 5.005_02 using perl's malloc, and the default shared memory
segment size.  Each test was run 5000 times.

 	DATA SIZE (bytes)	TIME (seconds)	Op/Sec

 store	16384			2		2500
 fetch	16384			2		2500

 store	32768			3		1666	
 fetch	32768			3		1666	

 store	65536			6		833
 fetch	65536			5		1000	

 store	131072			12		416	
 fetch	131072			12		416	

 store	262144			28		178	
 fetch  262144			27		185	

 store	524288			63		79	
 fetch  524288			61		81	

Most of the time appears to be due to memory copying.  
Suggestions for speed improvements are welcome.

=head1 PORTABILITY

The module should compile on any system with SysV IPC and
an ANSI C compiler, and should compile cleanly with the
-pedantic and -Wall flags.

The module has been tested under Solaris, FreeBSD, and Linux.
Testing on other platforms is needed.  

If you encounter a compilation error due to the definition
of the semun union, edit the top of sharestuff.c and undefine
the semun definition.  And then please tell me about it.

I've heard rumors that a SysV IPC interface has been 
constructed for Win32 systems.  Support for it may be
added to this module.

IPC::ShareLite does not understand the shared memory
data format used by IPC::Shareable.  

=head1 AUTHOR

Copyright 1998-2002, Maurice Aubrey <maurice@hevanet.com>. 
All rights reserved.

This release by Andy Armstrong <andy@hexten.net>.

This module is free software; you may redistribute it and/or
modify it under the same terms as Perl itself. 

=head1 CREDITS

Special thanks to Benjamin Sugars for developing the
IPC::Shareable module.

See the Changes file for other contributors.

=head1 SEE ALSO

L<IPC::Shareable>, ipc(2), shmget(2), semget(2), perl.

=cut
