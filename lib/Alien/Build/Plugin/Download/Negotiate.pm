package Alien::Build::Plugin::Download::Negotiate;

use strict;
use warnings;
use Alien::Build::Plugin;
use Carp ();

# ABSTRACT: Download negotiation plugin
# VERSION

has '+url' => sub { Carp::croak "url is a required property" };
has 'filter'  => undef;
has 'version' => undef;
has 'ssl'     => 0;

sub init
{
  my($self, $meta) = @_;
  
  my $url = $self->url;
  my($scheme) = $url =~ m!^/! ? 'file' : $url =~ m!^(.*?):!;
  
  my $fetch;
  
  if($scheme =~ /^https?$/)
  {
    $fetch = 'HTTPTiny';
  }
  elsif($scheme eq 'ftp')
  {
    if($ENV{ftp_proxy} || $ENV{all_proxy})
    {
      $fetch = 'LWP';
    }
    else
    {
      $fetch = 'NetFTP';
    }
  }
  elsif($scheme eq 'ftps')
  {
    $fetch = 'LWP';
  }
  elsif($scheme eq 'file')
  {
    # TODO: use Fetch::File instead
    $fetch = 'LWP';
    $url = "file:///$url";
  }
  else
  {
    die "do not know how to handle scheme $scheme for $url";
  }
  
  $self->_plugin($meta, 'Fetch', $fetch, url => $url, ssl => $self->ssl);
  
  if($self->version)
  {
    if($fetch eq 'NetFTP')
    {
      # no decoder necessary
    }
    elsif($fetch eq 'LWP' && $scheme =~ /^ftps?/)
    {
      $self->_plugin($meta, 'Decode', 'DirListing');
    }
    else
    {
      $self->_plugin($meta, 'Decode', 'HTML');
    }
    
    $self->_plugin($meta, 'Prefer', 'SortVersions', 
      (defined $self->filter ? (filter => $self->filter) : ()),
      version => $self->version,
    );
  }
}

sub _plugin
{
  my($self, $meta, $type, $name, @args) = @_;
  my $class = "Alien::Build::Plugin::${type}::$name";
  my $pm    = "Alien/Build/Plugin/$type/$name.pm";
  require $pm;
  my $plugin = $class->new(@args);
  $plugin->init($meta);
  
}

1;
