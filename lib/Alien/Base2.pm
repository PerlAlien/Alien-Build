package Alien::Base2;

use strict;
use warnings;
use base qw( Alien::Base );

# ABSTRACT: Intermediate base class for Aliens
# VERSION

=head1 SYNOPSIS

 package Alien::MyLib;
 
 use strict;
 use warnings;
 use base qw( Alien::Base2 );
 
 1;

=head1 DESCRIPTION

This is an I<experimental> subclass of L<Alien::Base> for use with L<Alien::Build>.  The
intention is for this class to eventually go away, and thus only of use for Alien developers
working on the bleeding edge.  If you want to use some of the advanced features of
L<Alien::Build> please make sure you hang out on the C<#native> IRC channel for Alien
developers.

=head1 SEE ALSO

=over 4

=item L<Alien::Base>

=item L<Alien::Build>

=back

=cut

1;
