package Alien::Role;

use strict;
use warnings;

# ABSTRACT: Extend Alien::Base with roles!
# VERSION

=head1 SYNOPSIS

 package Alien::libfoo;

 use base qw( Alien::Base );
 use Role::Tiny::With qw( with );

 with 'Alien::Role::Dino';
 with 'Alien::Role::Alt';

 1;

=head1 DESCRIPTION

The C<Alien::Role> namespace is intended for writing roles that can be
applied to L<Alien::Base> to extend its functionality.  You could of
course write subclasses that extend L<Alien::Base>, but then you have
to either stick with just one subclass or deal with multiple inheritance!
It is recommended that you use L<Role::Tiny> since it can be used on
plain old Perl classes which is good since L<Alien::Base> doesn't use
anything fancy like L<Moose> or L<Moo>.  There are two working examples
that use this technique that are worth checking out in the event you
are interested: L<Alien::Role::Dino> and L<Alien::Role::Alt>.

This class itself doesn't do anything, it just documents the technique.

=head1 SEE ALSO

=over 4

=item L<Alien>

=item L<Alien::Base>

=item L<alienfile>

=item L<Alien::Build>

=item L<Alien::Role::Dino>

=item L<Alien::Role::Alt>

=back

=cut

1;
