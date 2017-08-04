package Alien::Build::Plugin::Build::MSYS;

use strict;
use warnings;
use Alien::Build::Plugin;
use File::Which ();
use Env qw( @PATH );

# ABSTRACT: MSYS plugin for Alien::Build
# VERSION

=head1 SYNOPSIS

 use alienfile;
 plugin 'Build::MSYS' => ();

=head1 DESCRIPTION

This plugin sets up the MSYS environment for your build on Windows.  It does
not do anything on non-windows platforms.  MSYS provides the essential tools
for building software that is normally expected in a UNIX or POSIX environment.
This like C<sh>, C<awk> and C<make>.  To provide MSYS, this plugin uses
L<Alien::MSYS>.

=cut

sub init
{
  my($self, $meta) = @_;
  
  if(_win_and_needs_msys())
  {
    $meta->add_requires('share' => 'Alien::MSYS' => '0.07');
    
    $meta->around_hook(
      build => sub {
        my $orig = shift;
        my $build = shift;

        local $ENV{PATH} = $ENV{PATH};
        unshift @PATH, Alien::MSYS::msys_path();

        $orig->($build, @_);
      },
    );

=head1 HELPERS

=head2 make

 %{make}

On windows the default C<%{make}> helper is replace with the make that comes with
L<Alien::MSYS>.  This is almost certainly what you want, as most unix style make
projects will not build with C<nmake> or C<dmake> typically used by Perl on Windows.

=cut
  
    # Most likely if we are trying to build something unix-y and
    # we are using MSYS, then we want to use the make that comes
    # with MSYS.
    $meta->interpolator->replace_helper(
      make => sub { 'make' },
    );

  }
  
  $self;
}

sub _win_and_needs_msys
{
  # check to see if we are running on windows.
  # if we are running on windows, check to see if
  # it is MSYS2, then we can just use that.  Otherwise
  # we are probably on Strawberry, or (less likely)
  # VC Perl, in which case we will still need Alien::MSYS
  return 0 unless $^O eq 'MSWin32';
  my $uname_exe = File::Which::which('uname');
  return 1 unless $uname_exe;
  my $uname = `$uname_exe`;
  chomp $uname;
  return 0 if $uname =~ /^(MSYS|MINGW32|MINGW64)_NT/;
  return 1;
}

1;

=head1 SEE ALSO

L<Alien::Build::Plugin::Autoconf>, L<Alien::Build::Plugin>, L<Alien::Build>, L<Alien::Base>, L<Alien>

L<http://www.mingw.org/wiki/MSYS>

=cut