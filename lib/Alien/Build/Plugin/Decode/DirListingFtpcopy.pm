package Alien::Build::Plugin::Decode::DirListingFtpcopy;

use strict;
use warnings;
use Alien::Build::Plugin;
use File::Basename ();

# ABSTRACT: Plugin to extract links from a directory listing using ftpcopy
# VERSION

sub init
{
  my($self, $meta) = @_;

  $meta->add_requires('share' => 'File::Listing::Ftpcopy' => 0);
  $meta->add_requires('share' => 'URI' => 0);
  
  $meta->register_hook( decode_dir_listing => sub {
    my($res) = @_;
    
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
        } File::Listing::Ftpcopy::parse_dir($res->{content})
      ],
    };
  });

  $self;
}

1;
