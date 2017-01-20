package Alien::Build::Plugin::Decode::HTML;

use strict;
use warnings;
use Alien::Build::Plugin;
use File::Basename ();

# ABSTRACT: Plugin to extract links from HTML
# VERSION

sub init
{
  my($self, $meta) = @_;

  $meta->add_requires('share' => 'HTML::LinkExtor' => 0);
  $meta->add_requires('share' => 'URI' => 0);
  
  $meta->register_hook( decode => sub {
    my(undef, $res) = @_;
    
    die "do not know how to decode @{[ $res->{type} ]}"
      unless $res->{type} eq 'html';
    
    my $base = URI->new($res->{base});
    
    my @list;
    
    my $p = HTML::LinkExtor->new(sub {
      my($tag, %links) = @_;
      if($tag eq 'base' && $links{href})
      {
        $base = URI->new($links{href});
      }
      elsif($tag eq 'a' && $links{href})
      {
        my $href = $links{href};
        return if $href =~ m!^\.\.?/?$!;
        my $url = URI->new_abs($href, $base);
        push @list, {
          filename => File::Basename::basename($url->path),
          url      => $url->as_string,
        };
      }
    });
    
    $p->parse($res->{content});
    
    return {
      type => 'list',
      list => \@list,
    };
  });

  $self;
}

1;
