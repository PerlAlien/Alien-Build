package Alien::Build::Plugin::Fetch::LWP;

use strict;
use warnings;
use Alien::Build::Plugin;
use Carp ();

# ABSTRACT: LWP plugin for fetching files
# VERSION

has '+url' => sub { Carp::croak "url is a required property" };

sub init
{
  my($self, $meta) = @_;

  $meta->add_requires('share' => 'LWP::UserAgent' => 0 );
  
  $meta->register_hook( share => fetch => sub {
    my(undef, $url) = @_;
    $url ||= $self->url;

    my $ua = LWP::UserAgent->new;
    $ua->env_proxy;
    my $res = $ua->get($url);

    die "error fetching $url: @{[ $res->status_line ]}"
      unless $res->is_success;

    my($type, $charset) = $res->content_type_charset;
    my $base            = $res->base;
    my $filename        = $res->filename;

    if($type eq 'text/html')
    {
      return {
        type    => 'html',
        charset => $charset,
        base    => "$base",
        content => $res->decoded_content,
      };
    }
    elsif($type eq 'text/ftp-dir-listing')
    {
      return {
        type => 'dir_listing',
        base => "$base",
        content => $res->decoded_content,
      };
    }
    else
    {
      return {
        type     => 'file',
        filename => $filename || 'downloadedfile',
        content  => $res->content,
      };
    }
    
  });

  $self;
}

1;
