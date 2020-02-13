package Alien::Build::Interpolate::Default;

use strict;
use warnings;
use base qw( Alien::Build::Interpolate );
use File::chdir;
use File::Which qw( which );
use Capture::Tiny qw( capture );

# ABSTRACT: Default interpolator for Alien::Build
# VERSION

sub _config
{
  $Config::Config{$_[0]};
}

=head1 CONSTRUCTOR

=head2 new

 my $intr = Alien::Build::Interpolate::Default->new;

=cut

sub new
{
  my($class) = @_;
  my $self = $class->SUPER::new(@_);

=head1 HELPERS

=head2 ar

 %{ar}

The ar command.

=cut

  $self->add_helper( ar => sub { _config 'ar' }, 'Config' );

=head2 bison

 %{bison}

Requires: L<Alien::bison> 0.17 if not already in C<PATH>.

=cut

  $self->add_helper( bison => undef, sub {
    my $helper = shift;
    if(which 'bison')
    {
      $helper->code(sub { 'bison' });
      return  ();
    }
    else
    {
      return 'Alien::bison' => '0.17';
    }
  });

=head2 bzip2

 %{bzip2}

Requires: L<Alien::Libbz2> 0.04 if not already in C<PATH>.

=cut

  $self->add_helper( bzip2 => undef, sub {
    my $helper = shift;
    if(which 'bzip2')
    {
      $helper->code( sub { 'bzip2' });
      return ();
    }
    else
    {
      return 'Alien::Libbz2' => '0.04';
    }
  });

=head2 cc

 %{cc}

The C Compiler used to build Perl

=cut

  $self->add_helper( cc => sub { _config 'cc' }, 'Config' );

=head2 cmake

 %{cmake}

Requires: L<Alien::CMake> 0.07 if cmake is not already in C<PATH>.

Deprecated: Use the L<Alien::Build::Plugin::Build::CMake> plugin instead (which will replace
this helper with one that works with L<Alien::cmake3> that works better).

=cut

  $self->add_helper( cmake => sub { 'cmake' }, sub {
    if(which 'cmake')
    {
      return ();
    }
    else
    {
      return 'Alien::CMake' => '0.07';
    }
  });

=head2 cp

 %{cp}

The copy command.

=cut

  $self->add_helper( cp => sub { _config 'cp' }, 'Config' );

=head2 devnull

 %{devnull}

The null device, if available.  On Unix style operating systems this will be C</dev/null> on Windows it is C<NUL>.

=cut

  $self->add_helper( devnull => sub { $^O eq 'MSWin32' ? 'NUL' : '/dev/null' });

=head2 flex

 %{flex}

Requires: L<Alien::flex> 0.08 if not already in C<PATH>.

=cut

  $self->add_helper( flex => undef, sub {
    my $helper = shift;
    if(which 'flex')
    {
      $helper->code(sub { 'flex' });
      return  ();
    }
    else
    {
      return 'Alien::flex' => '0.08';
    }
  });

=head2 gmake

 %{gmake}

Requires: L<Alien::gmake> 0.11

Deprecated: use L<Alien::Build::Plugin::Build::Make> instead.

=cut

  $self->add_helper( gmake => undef, 'Alien::gmake' => '0.11' );

=head2 install

 %{install}

The Unix C<install> command.  Not normally available on Windows.

=cut

  $self->add_helper( install => sub { 'install' });

=head2 ld

 %{ld}

The linker used to build Perl

=cut

  $self->add_helper( ld => sub { _config 'ld' }, 'Config' );

=head2 m4

 %{m4}

Requires: L<Alien::m4> 0.08

L<Alien::m4> should pull in a version of C<m4> that will work with Autotools.

=cut

  $self->add_helper( m4 => undef, 'Alien::m4' => '0.08' );

=head2 make

 %{make}

The make program used by Perl.

=cut

  $self->add_helper( make => sub { _config 'make' }, 'Config' );

=head2 make_path

 %{make_path}

Make directory, including all parent directories as needed.  This is usually C<mkdir -p>
on Unix and simply C<md> on windows.

=cut

  $self->add_helper( mkdir_deep => sub { $^O eq 'MSWin32' ? 'md' : 'mkdir -p'}, 'Alien::Build' => '1.04' );
  $self->add_helper( make_path  => sub { $^O eq 'MSWin32' ? 'md' : 'mkdir -p'}, 'Alien::Build' => '1.05' );

=head2 nasm

 %{nasm}

Requires: L<Alien::nasm> 0.11 if not already in the C<PATH>.

=cut

  $self->add_helper( nasm => undef, sub {
    my $helper = shift;
    if(which 'nasm')
    {
      $helper->code(sub { 'nasm' });
      return  ();
    }
    else
    {
      return 'Alien::nasm' => '0.11';
    }
  });

=head2 patch

 %{patch}

Requires: L<Alien::patch> 0.09 if not already in the C<PATH>.

On Windows this will normally render C<patch --binary>, which makes patch work like it does on Unix.

=cut

  $self->add_helper( patch => undef, sub {
    my $helper = shift;
    if(which 'patch')
    {
      if($^O eq 'MSWin32')
      {
        $helper->code(sub { 'patch --binary' });
      }
      else
      {
        $helper->code(sub { 'patch' });
      }
      return  ();
    }
    else
    {
      return 'Alien::patch' => '0.09';
    }
  });

=head2 perl

 %{perl}

Requires: L<Devel::FindPerl>

=cut

  $self->add_helper( perl => sub {
      my $perl = Devel::FindPerl::find_perl_interpreter();
      $perl =~ s{\\}{/}g if $^O eq 'MSWin32';
      $perl;
  }, 'Devel::FindPerl' );

=head2 pkgconf

 %{pkgconf}

Requires: L<Alien::pkgconf> 0.06.

=cut

  $self->add_helper( pkgconf => undef, 'Alien::pkgconf' => 0.06 );

=head2 cwd

 %{cwd}

=cut

  $self->add_helper( cwd => sub {
    my $cwd = "$CWD";
    $cwd =~ s{\\}{/}g if $^O eq 'MSWin32';
    $cwd;
  } );

=head2 sh

 %{sh}

Unix style command interpreter (/bin/sh).

Deprecated: use the L<Alien::Build::Plugin::Build::MSYS> plugin instead.

=cut

  $self->add_helper( sh => sub { 'sh' }, 'Alien::MSYS' => '0.07' );

=head2 rm

 %{rm}

The remove command

=cut

  $self->add_helper( rm => sub { _config 'rm' }, 'Config' );


=head2 xz

 %{xz}

Requires: L<Alien::xz> 0.02 if not already in the C<PATH>.

=cut

  $self->add_helper( xz => undef, sub {
    my $helper = shift;
    if(which 'xz')
    {
      $helper->code(sub { 'xz' });
      return  ();
    }
    else
    {
      return 'Alien::xz' => '0.02';
    }
  });

  $self;
}

1;
