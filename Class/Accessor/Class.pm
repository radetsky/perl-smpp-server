package Class::Accessor::Class;
use base qw(Class::Accessor);

use warnings;
use strict;

=head1 NAME

Class::Accessor::Class - simple class variable accessors

=head1 VERSION

version 0.501

 $Id: /my/cs/projects/claccl/trunk/lib/Class/Accessor/Class.pm 27922 2006-11-13T16:05:47.533928Z rjbs  $

=cut

our $VERSION = '0.501';

=head1 SYNOPSIS

Set up a module with class accessors:

 package Text::Fortune;

 use base qw(Class::Accessor::Class Exporter);
 Robot->mk_class_accessors(qw(language offensive collection));

 sub fortune { 
   if (__PACKAGE__->offensive) {
	 ..

Then, when using the module:

 use Text::Fortune;

 Text::Fortune->offensive(1);

 print fortune; # prints an offensive fortune

 Text::Fortune->language('EO');

 print fortune; # prints an offensive fortune in Esperanto

=head1 DESCRIPTION

Class::Accessor::Class provides a simple way to create accessor and mutator
methods for class variables, just as Class::Accessor provides for objects.  It
can use either an enclosed lexical variable, or a package variable.

This module was once implemented in terms of Class::Accessor, but changes to
that module broke this relationship.  Class::Accessor::Class is still a
subclass of Class::Accessor, strictly for historical reasons.  As a side
benefit, a class that isa Class::Accessor::Class is also a Class::Accessor
and can use its methods.

=head1 METHODS

=head2 mk_class_accessors

 package Foo;
 use base qw(Class::Accessor::Class);
 Foo->mk_class_accessors(qw(foo bar baz));

 Foo->foo(10);
 my $obj = new Foo;
 print $obj->foo;   # 10

This method adds accessors for the named class variables.  The accessor will
get or set a lexical variable to which the accessor is the only access.

=cut

sub mk_class_accessors {
	my ($self, @fields) = @_;

  ## no critic (ProhibitNoStrict)
  no strict 'refs';
  for my $field (@fields) {
    *{"${self}::$field"} = $self->make_class_accessor($field);
  }
}

=head2 mk_package_accessors

 package Foo;
 use base qw(Class::Accessor::Class);
 Foo->mk_package_accessors(qw(foo bar baz));

 Foo->foo(10);
 my $obj = new Foo;
 print $obj->foo;   # 10
 print $Foo::foo;    # 10

This method adds accessors for the named class variables.  The accessor will
get or set the named variable in the package's symbol table.

=cut

sub mk_package_accessors {
	my ($self, @fields) = @_;

  ## no critic (ProhibitNoStrict)
  no strict 'refs';
  for my $field (@fields) {
    *{"${self}::$field"} = $self->make_package_accessor($field);
  }
}

=head1 DETAILS

=head2 make_class_accessor

 $accessor = Class->make_class_accessor($field);

This method generates a subroutine reference which acts as an accessor for the
named field. 

=cut

{
	my %accessor;

	sub make_class_accessor {
		my ($class, $field) = @_;

		return $accessor{$class}{$field}
			if $accessor{$class}{$field};

		my $field_value;

		$accessor{$class}{$field} = sub {
			my $class = shift;

			return @_
				? ($field_value = $_[0])
				:  $field_value;
		}
	}
}

=head2 make_package_accessor

 $accessor = Class->make_package_accessor($field);

This method generates a subroutine reference which acts as an accessor for the
named field, which is stored in the scalar named C<field> in C<Class>'s symbol
table.

This can be useful for dealing with legacy code, but using package variables is
almost never a good idea for new code.  Use this with care.

=cut

sub make_package_accessor {
	my ($self, $field) = @_;
	my $class = ref $self || $self;

	my $varname = "$class\:\:$field";
	return sub {
		my $class = shift;

    ## no critic (ProhibitNoStrict)
    no strict 'refs';
		return @_
			? (${$varname} = $_[0])
			:  ${$varname}
	}
}

=head1 AUTHOR

Ricardo SIGNES, C<< <rjbs@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-class-accessor-class@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT

Copyright 2004-2006 Ricardo Signes, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
