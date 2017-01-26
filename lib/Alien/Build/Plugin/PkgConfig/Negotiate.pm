package Alien::Build::Plugin::PkgConfig::Negotiate;

use strict;
use warnings;
use Alien::Build::Plugin;
use Carp ();

# ABSTRACT: Package configuration negotiation plugin
# VERSION

has '+pkg_name' => sub {
  Carp::croak "pkg_name is a required property";
};

sub init
{
  my($self, $meta) = @_;
  
  if(eval q{ use PkgConfig::LibPkgConf 0.04; 1 })
  {
    my $plugin = _plugin('LibPkgConf', pkg_name => $self->pkg_name);
    $plugin->init($meta);
    return $self;
  }

  {
    my $plugin = _plugin('CommandLine', pkg_name => $self->pkg_name);
    if($plugin->bin_name)
    {
      $plugin->init($meta);
      return $self;
    }
  }

  # Q: should PkgConfig.pm be before or after CommandLine?
  {
    my $plugin = _plugin('PP', pkg_name => $self->pkg_name);
    $plugin->init($meta);
    return $self;
  }
}

sub _plugin
{
  my($name, @args) = @_;
  my $class = "Alien::Build::Plugin::PkgConfig::$name";
  my $pm    = "Alien/Build/Plugin/PkgConfig/$name.pm";
  require $pm;
  $class->new(@args);
}

1;
