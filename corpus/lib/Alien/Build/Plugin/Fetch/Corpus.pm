package Alien::Build::Plugin::Fetch::Corpus;

use strict;
use warnings;
use Alien::Build::Plugin;
use Carp ();
use Path::Tiny ();

sub _path { Path::Tiny::path(@_) }

has '+url' => sub {
  Carp::croak "url is required";
};

has return_listing_as => 'list';    # or html or dir_listing
has return_file_as    => 'content'; # or path

has regex => qr/\.tar\.gz$/;

sub init
{
  my($self, $meta) = @_;
  
  my $list = {
    type => 'list',
    list => [
      map {
        my %h = (
          filename => $_,
          url      => "http://test1.test/foo/bar/baz/$_",
        );
        \%h;
      } ((map { $_->basename } grep { -f $_ } _path('corpus/dist')->children), map { sprintf "foo-0.%02d.tar.gz", $_ } 0..99),
    ],
  };
  
  $meta->register_hook(
    fetch => sub {
      my(undef, $url) = @_;
      
      $url ||= $self->url;
      
      if($url =~ qr!^http://test1\.test/foo/bar/baz/?$!)
      {
        if($self->return_listing_as eq 'list')
        {
          return $list;
        }
        elsif($self->return_listing_as =~ /^(?:html|dir_listing)$/)
        {
          return {
            type    => $self->return_listing_as,
            base    => 'http://test1.test/foo/bar/baz/',
            content => 'test content',
          };
        }
        else
        {
          die "todo: @{[ $self->return_listing_as ]}";
        }
      }
      elsif($url =~ qr!^http://test1\.test/foo/bar/baz/(.*)$!)
      {
        my $path = _path "corpus/dist/$1";
        if(-f $path)
        {
          my %hash = (
            type     => 'file',
            filename => $path->basename,
          );
          if($self->return_file_as eq 'content')
          {
            $hash{content} = $path->slurp_raw;
          }
          elsif($self->return_file_as eq 'path')
          {
            $hash{path} = $path->stringify;
          }
          return \%hash;
        }
        else
        {
          die "bad file: @{[ $path->basename ]}";
        }
      }
      else
      {
        die "bad url: $url";
      }
    },
  );
  
  $meta->register_hook(
    decode => sub {
      return $list;
    }
  );
  
  $meta->register_hook(
    sort => sub {
      my(undef, $res) = @_;
      
      my @list = sort { $b->{filename} cmp $a->{filename} }
                 grep { $_->{filename} =~ $self->regex }
                 @{ $res->{list} };
      
      return {
        type => 'list',
        list => \@list,
      };
    }
  );
}

1;

