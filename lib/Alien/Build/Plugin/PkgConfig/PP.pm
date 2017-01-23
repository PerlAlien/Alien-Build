package Alien::Build::Plugin::PkgConfig::PP;

use strict;
use warnings;
use Alien::Build::Plugin;
use Carp ();

has '+pkg_name' => sub {
  Carp::croak "pkg_name is a required property";
};

has minimum_version => undef;

sub _cleanup
{
  my($value) = @_;
  $value =~ s{\s*$}{ };
  $value;
}

sub init
{
  my($self, $meta) = @_;
  
  if($^O eq 'linux')
  {
    # includes support Gentoo Linux, which we could be
    # running when $^O eq 'linux'
    $meta->add_requires('any' => 'PkgConfig' => '0.09026');
  }
  elsif($self->minimum_version)
  {
    # added support for --atleast-version
    $meta->add_requires('any' => 'PkgConfig' => '0.08926');
  }
  elsif($^O eq 'sun')
  {
    # fixes for 64bit solaris
    $meta->add_requires('any' => 'PkgConfig' => '0.08826');  
  }
  else
  {
    # baseline includes support for a number of envs
    # and lots of Windows fixes.
    $meta->add_requires('any' => 'PkgConfig' => '0.08826');  
  }

  $meta->register_hook(
    probe => sub {
      my $pkg = PkgConfig->find($self->pkg_name);
      return 'share' if $pkg->errmsg;
      if($self->minimum_version)
      {
        my $version = PkgConfig::Version->new($pkg->pkg_version);
        my $need    = PkgConfig::Version->new($self->minimum_version);
        if($version < $need)
        {
          return 'share';
        }
      }
      'system';
    },
  );
  
  $meta->register_hook(
    gather_system => sub {
      my($build) = @_;
      my $pkg = PkgConfig->find($self->pkg_name);
      die "second load of PkgConfig.pm @{[ $self->pkg_name ]} failed: @{[ $pkg->errmsg ]}"
        if $pkg->errmsg;
      $build->runtime_prop->{cflags}  = _cleanup scalar $pkg->get_cflags;
      $build->runtime_prop->{libs}    = _cleanup scalar $pkg->get_ldflags;
      $build->runtime_prop->{version} = $pkg->pkg_version;
      # pkg-config --cflags, libs version
    },
  );
  
  $self;
}

1;
