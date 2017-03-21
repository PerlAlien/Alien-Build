package Alien::Base::Wrapper;

use strict;
use warnings;
use 5.008001;
use Config;
use Text::ParseWords qw( shellwords );

# ABSTRACT: Compiler and linker wrapper for late optional Alien utilization
# VERSION

=head1 SYNOPSIS

 % perl -MAlien::Base::Wrapper=Alien::Foo,Alien::Bar -e cc -o foo.o -c foo.c
 % perl -MAlien::Base::Wrapper=Alien::Foo,Alien::Bar -e ld -o foo foo.o

=head1 DESCRIPTION

B<Note>: this particular module is still somewhat experimental.

This module provides a command line wrapper for L<Alien> modules that are
based on L<Alien::Base>.  The idea is to eventually use this to allow optional
use of L<Alien> modules by XS which cannot probe for a system library.
Historically an XS module that wanted to use an L<Alien> had to I<always> have
it as a prerequisite.

=cut

my @cflags_I;
my @cflags;
my @ldflags_L;
my @libs;

sub _reset
{
  @cflags_I  = ();
  @cflags    = ();
  @ldflags_L = ();
  @libs      = ();
}

=head1 FUNCTIONS

=head2 cc

 % perl -MAlien::Base::Wrapper=Alien::Foo -e cc cflags

Invoke the C compiler with the appropriate flags from C<Alien::Foo> and what
is provided on the command line.

=cut

sub cc
{
  my @command = (
    $Config{cc},
    @cflags_I,
    @cflags,
    @ARGV,
  );
  print "@command\n" unless $ENV{ALIEN_BASE_WRAPPER_QUIET};
  exec @command;
}

=head2 ld

 % perl -MAlien::Base::Wrapper=Alien::Foo -e ld ldflags

Invoke the linker with the appropriate flags from C<Alien::Foo> and what
is provided on the command line.

=cut

sub ld
{
  my @command = (
    $Config{ld},
    @ldflags_L,
    @ARGV,
    @libs,
  );
  print "@command\n" unless $ENV{ALIEN_BASE_WRAPPER_QUIET};
  exec @command;
}

sub import
{
  my(undef, @aliens) = @_;
  {
    my $caller = caller;
    no strict 'refs';
    *{"${caller}::cc"} = \&cc;
    *{"${caller}::ld"} = \&ld;
  }
  
  foreach my $alien (@aliens)
  {
    $alien = "Alien::$alien" unless $alien =~ /::/;
    my $alien_pm = $alien . '.pm';
    $alien_pm =~ s/::/\//g;
    require $alien_pm unless eval { $alien->can('cflags') } && eval { $alien->can('libs') };
    my $cflags;
    my $libs;
    if($alien->install_type eq 'share' && $alien->can('cflags_static'))
    {
      $cflags = $alien->cflags_static;
      $libs   = $alien->libs_static;
    }
    else
    {
      $cflags = $alien->cflags;
      $libs   = $alien->libs;
    }
    
    @cflags_I  = grep  /^-I/, shellwords $cflags;
    @cflags    = grep !/^-I/, shellwords $cflags;
    
    @ldflags_L = grep  /^-L/, shellwords $libs;
    @libs      = grep !/^-L/, shellwords $libs;
  }
}

1;

=head1 ENVIRONMENT

Alien::Base::Wrapper responds to these environment variables:

=over 4

=item ALIEN_BASE_WRAPPER_QUIET

Do not print the command before executing

=back

=head1 SEE ALSO

L<Alien::Base>, L<Alien::Base>

=cut
