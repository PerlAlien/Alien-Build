package Alien::Build::Plugin::PkgConfig::LibPkgConf;

use strict;
use warnings;
use Alien::Build::Plugin;
use Carp ();

# ABSTRACT: Probe system and determine library or tool properties using PkgConfig::LibPkgConf
# VERSION

has '+pkg_name' => sub {
  Carp::croak "pkg_name is a required property";
};

has minimum_version => undef;

sub init
{
  my($self, $meta) = @_;
  
  $meta->add_requires('any' => 'PkgConfig::LibPkgConf::Client' => '0.04');
  
  if(defined $self->minimum_version)
  {
    $meta->add_requires('any' => 'PkgConfig::LibPkgConf::Util' => '0.04');
  }
  
  my $client;
  
  $meta->register_hook(
    probe => sub {
      $client ||= PkgConfig::LibPkgConf::Client->new;
      my $pkg = $client->find($self->pkg_name);
      return 'share' unless $pkg;
      if(defined $self->minimum_version)
      {
        if(PkgConfig::LibPkgConf::Util::compare_version($pkg->version, $self->minimum_version) == -1)
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
      $client ||= PkgConfig::LibPkgConf::Client->new;
      my $pkg = $client->find($self->pkg_name);
      die "reload of package failed" unless defined $pkg;
      
      $build->runtime_prop->{version}        = $pkg->version;
      $build->runtime_prop->{cflags}         = $pkg->cflags;
      $build->runtime_prop->{libs}           = $pkg->libs;
      $build->runtime_prop->{cflags_static}  = $pkg->cflags_static;
      $build->runtime_prop->{libs_static}    = $pkg->libs_static;
    },
  );
  
  $self;
}

1;