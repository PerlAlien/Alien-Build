package Alien::Build::Plugin::Fetch::HTTPTiny;

use strict;
use warnings;
use Alien::Build::Plugin;
use File::Basename ();
use Carp ();

# ABSTRACT: LWP plugin for fetching files
# VERSION

has '+url' => sub { Carp::croak "url is a required property" };
has ssl => 0;

sub init
{
  my($self, $meta) = @_;

  $meta->add_requires('share' => 'HTTP::Tiny' => '0.044' );
  $meta->add_requires('share' => 'URI' => 0 );

  if($self->url =~ /^https:/ || $self->ssl)
  {
    $meta->add_requires('share' => 'IO::Socket::SSL' => '1.56' );
    $meta->add_requires('share' => 'Net::SSLeay'     => '1.49' );
  }
  
  $meta->register_hook( fetch => sub {
    my(undef, $url) = @_;
    $url ||= $self->url;

    my $ua = HTTP::Tiny->new;
    my $res = $ua->get($url);

    unless($res->{success})
    {
      my $status = $res->{status} || '---';
      my $reason = $res->{reason} || 'unknown';
      die "error fetching $url: $status $reason";
    }

    my($type) = split ';', $res->{headers}->{'content-type'};
    $type = lc $type;
    my $base            = URI->new($res->{url});
    my $filename        = File::Basename::basename $base->path;

    # TODO: this doesn't get exercised by t/bin/httpd
    if(my $disposition = $res->{headers}->{"content-disposition"})
    {
      # Note: from memory without quotes does not match the spec,
      # but many servers actually return this sort of value.
      if($disposition =~ /filename="([^"]+)"/ || $disposition =~ /filename=([^\s]+)/)
      {
        $filename = $1;
      }
    }
    
    if($type eq 'text/html')
    {
      return {
        type    => 'html',
        base    => $base->as_string,
        content => $res->{content},
      };
    }
    else
    {
      return {
        type     => 'file',
        filename => $filename || 'downloadedfile',
        content  => $res->{content},
      };
    }
    
  });

  $self;
}

1;
