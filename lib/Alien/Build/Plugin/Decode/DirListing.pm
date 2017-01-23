package Alien::Build::Plugin::Decode::DirListing;

use strict;
use warnings;
use Alien::Build::Plugin;
use File::Basename ();

# ABSTRACT: Plugin to extract links from a directory listing
# VERSION

sub init
{
  my($self, $meta) = @_;

  $meta->add_requires('share' => 'File::Listing' => 0);
  $meta->add_requires('share' => 'URI' => 0);
  
  $meta->register_hook( decode => sub {
    my(undef, $res) = @_;
    
    die "do not know how to decode @{[ $res->{type} ]}"
      unless $res->{type} eq 'dir_listing';
    
    my $base = URI->new($res->{base});
    
    return {
      type => 'list',
      list => [
        map {
          my($name) = @$_;
          my %h = (
            filename => File::Basename::basename($name),
            url      => URI->new_abs($name, $base)->as_string,
          );
          \%h;
        } File::Listing::parse_dir($res->{content})
      ],
    };
  });

  $self;
}

1;
