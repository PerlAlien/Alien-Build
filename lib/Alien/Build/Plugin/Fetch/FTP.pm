package Alien::Build::Plugin::Fetch::FTP;

use strict;
use warnings;
use Alien::Build::Plugin;
use Carp ();
use File::Temp ();
use Path::Tiny qw( path );

# ABSTRACT: LWP plugin for fetching files
# VERSION

has '+url' => sub { Carp::croak "url is a required property" };

sub init
{
  my($self, $meta) = @_;

  $meta->add_requires('share' => 'Net::FTP' => 0 );
  $meta->add_requires('share' => 'URI' => 0 );
  $meta->register_hook( share => fetch => sub {
    my(undef, $url) = @_;
    $url ||= $self->url;
    
    $url = URI->new($url);
    
    my $ftp = Net::FTP->new(
      $url->host, Port =>$url->port,
    ) or die "error fetching $url: $@";
    
    $ftp->login($url->user, $url->password)
      or die "error on login $url: @{[ $ftp->message ]}";
    
    $ftp->binary;

    my $path = $url->path;

    unless($path =~ m!/$!)
    {
      my(@parts) = split '/', $path;
      my $filename = pop @parts;
      my $dir      = join '/', @parts;
      
      my $path = eval {
        $ftp->cwd($dir) or die;
        my $dir = File::Temp::tempdir( CLEANUP => 1);
        my $path = path("$dir/$filename")->stringify;
        $ftp->get($filename, $path) or die;
        $path;
      };
      
      if(defined $path)
      {
        return {
          type     => 'file',
          filename => $filename,
          path     => $path,
        };
      }
      
      $path .= "/";
    }
    
    $ftp->cwd($path) or die "unable to fetch $url as either a directory or file";
    
    my @list = $ftp->ls;
    
    die "no files found at $url" unless @list;
    
    return {
      type => 'list',
      list => [
        map {
          my $filename = $_;
          my $furl = $url->clone;
          $furl->path($path . $filename);
          my %h = (
            filename => $filename,
            url      => $furl->as_string,
          );
          \%h;
        } sort @list,
      ],
    };
    
  });

  $self;
}

1;
