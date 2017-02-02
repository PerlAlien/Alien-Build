package Alien::Base2;

use strict;
use warnings;
use base qw( Alien::Base );
use Path::Tiny ();
use JSON::PP ();
use File::ShareDir ();

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

=head1 METHODS

=head2 dist_dir

 my $dir = Alien::Base2->dist_dir;

The dist share directory for the L<Alien> module.  This is usually where files are installed
when a C<share> install is performed.  It is also where the configuration files are stored
under either a C<share> or C<system> install.

=cut

sub dist_dir
{
  my($class) = @_;
  my $config = _alien_build_config($class);
  $config
    ? $config->{distdir}
    : $class->SUPER::dist_dir;
}

=head2 install_type

 my $type = Alien::Base2->install_type;

Returns the install type that was used when your module was installed.  Types include:

=over 4

=item system

The library was provided by the operating system.

=item share

The library was not available when the module was installed, so
it was built from source code.  Either downloaded from the internet
or bundled with the module.

=back

=cut

sub install_type
{
  my($class) = @_;
  my $config = _alien_build_config($class);
  $config
    ? $config->{install_type}
    : $class->SUPER::install_type;
}

=head2 version

 my $version = Alien::Base2->version;

Returns the version of the library or tool.

=cut

sub version
{
  my($class) = @_;
  my $config = _alien_build_config($class);
  $config
    ? $config->{version}
    : $class->SUPER::version;
}

=head2 cflags

 my $cflags = Alien::Base2->cflags;

Returns the compiler flags used to compile against the library.

=head2 cflags_static

 my $cflags = Alien::Base2->cflags_static;

Returns the static compiler flags used to compile against the library.

=cut

sub cflags_static
{
  my($class) = @_;
  return $class->_keyword('Cflags.private', @_);
}

=head2 libs

 my $libs = Alien::Base2->libs;

Returns the linker flags used to link against the library.

=head2 libs_static

 my $libs = Alien::Base2->libs_static;

Returns the static linker flags used to link against the library.

=cut

sub libs_static
{
  my($class) = @_;
  return $class->_keyword('Libs.private', @_);
}

sub _keyword
{
  my($class, $keyword) = @_;
  
  my $config = _alien_build_config($class);
  return $class->SUPER::_keyword($keyword) unless $config;
  
  $keyword = lc $keyword;
  $keyword =~ s/\.private$/_static/;
  
  my $flags = $config->{$keyword};
  if($keyword =~ /_static$/ && ! defined $flags)
  {
    $keyword =~ s/_static$//;
    $flags = $config->{$keyword};
  }
  
  if($config->{prefix} ne $config->{distdir})
  {
    my $prefix  = $config->{prefix};
    my $distdir = Path::Tiny->new($config->{distdir})->stringify; # make sure \ is /
    $flags = join ' ', map { 
      s/^(-I|-L|-LIBPATH:)?\Q$prefix\E/$1$distdir/;
      s/(\s)/\\$1/g;
      $_;
    } $class->split_flags($flags);
  }
  
  $flags;
}

=head2 config

 my $value = Alien::Base2->config($key);

This is an interface to the legacy configuration used by L<Alien::Base> in times
of yore.  Do not use it.

=cut

my %alien_base_config_cache;

sub config
{
  my($class, $key) = @_;
  my $config = _alien_build_config($class);
  return $class->SUPER::config($key) unless $config;
  
  my $old = $alien_base_config_cache{$class} ||= {
    finished_installing => 1,
    install_type        => $config->{install_type},
    version             => $config->{version},
    original_prefix     => $config->{prefix},
  };
  
  $old->{$key};
}

my %alien_build_config_cache;

sub _alien_build_config
{
  my($class) = @_;
  
  $alien_build_config_cache{$class} ||= do {
    my $dist = ref $class ? ref $class : $class;
    $dist =~ s/::/-/g;
    my $dist_dir = File::ShareDir::dist_dir($dist);
    my $alien_json = Path::Tiny->new($dist_dir)->child('_alien/alien.json');
    return unless -r $alien_json;
    my $config = JSON::PP::decode_json($alien_json->slurp);
    $config->{distdir} = $dist_dir;
    $config;
  };
}

sub import
{
  my($class) = @_;
  my $config = _alien_build_config($class);
  goto \&Alien::Base::import unless $config;
}

1;

=head1 SEE ALSO

=over 4

=item L<Alien::Base>

=item L<Alien::Build>

=back

