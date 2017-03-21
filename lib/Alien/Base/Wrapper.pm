package Alien::Base::Wrapper;

use strict;
use warnings;
use 5.008001;
use Config;
use Text::ParseWords qw( shellwords );

# ABSTRACT: Compiler and linker wrapper for late optional Alien utilization
# VERSION

=head1 SYNOPSIS

From the command line:

 % perl -MAlien::Base::Wrapper=Alien::Foo,Alien::Bar -e cc -- -o foo.o -c foo.c
 % perl -MAlien::Base::Wrapper=Alien::Foo,Alien::Bar -e ld -- -o foo foo.o

From Makefile.PL:

 use Config;
 use ExtUtils::MakeMaker 6.52;
 
 my $cc      = $Config{cc};
 my $ld      = $Config{ld};
 my $libs    = '';
 my $ccflags = $Config{ccflags};
 my %build_requires;
 
 system 'pkg-config', '--exists', 'libfoo';
 if($? == 0)
 {
   $ccflags = `pkg-config --cflags libfoo` . " $ccflags";
   $libs    = `pkg-config --libs   libfoo`;
 }
 else
 {
   $cc = '$(FULLPERL) -MAlien::Base::Wrapper=Alien::Libfoo -e cc --';
   $ld = '$(FULLPERL) -MAlien::Base::Wrapper=Alien::Libfoo -e ld --';
   $build_requires{'Alien::Libfoo'} = 0;
   $build_requires{'Alien::Base::Wrapper'} = 0;
 }
 
 WriteMakefile(
   NAME => 'Foo::XS',
   BUILD_REQUIRES => \%build_requires,
   CC             => $cc,
   LD             => $ld,
   CCFLAGS        => $ccflags,
   LIBS           => [ $libs ],
   ...
 );

=head1 DESCRIPTION

B<Note>: this particular module is still somewhat experimental.

This module provides a command line wrapper for your compiler and linker that use the 
correct flags needed for compiling and linking with L<Alien> modules.  The problem that 
this module attempts to solve is that compiler and linker flags typically need to be 
determined at I<configure> time when a distribution is installed, meaning if you are going 
to use an L<Alien> module, then it needs to be a configure prerequisite, even if the 
library is already installed on the operating system.  With this module, you can use this 
wrapper as the compiler and linker commands and delay computing the compiler and linker 
flags to the build stage, and only if necessary.

The author of this module believes it to be somewhat unnecessary.  L<Alien> modules based on 
L<Alien::Base> have a number of prerequisites, but they well maintained and reliable, so 
while there is a small cost in terms of extra dependencies, this is more than made up for 
in reliability on systems where libraries that are do not typically come with commonly used 
open source libraries.  Operating system vendors that are packaging XS perl modules may 
disagree.

If you wish to be extra minimal in your prerequisites you can bundle this module with
your XS module, and use C<-Iinc>.  This module has no non-core prerequisites on Perl
5.8.1 and better.

For a working example, please see the C<Makefile.PL> that comes with L<Term::EditLine>.

For a more custom, non L<Alien::Base> based example, see the C<Makefile.PL> that
comes with L<PkgConfig::LibPkgConf>.

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

 % perl -MAlien::Base::Wrapper=Alien::Foo -e cc -- cflags

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

 % perl -MAlien::Base::Wrapper=Alien::Foo -e ld -- ldflags

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
