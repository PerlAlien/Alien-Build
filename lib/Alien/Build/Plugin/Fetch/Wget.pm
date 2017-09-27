package Alien::Build::Plugin::Fetch::Wget;

use strict;
use warnings;
use Alien::Build::Plugin;
use File::Temp qw( tempdir );
use Path::Tiny qw( path );
use File::Which qw( which );
use Capture::Tiny qw( capture );
use File::chdir;

# ABSTRACT: Plugin for fetching files using wget
# VERSION

has wget_command => sub { defined $ENV{WGET} ? which($ENV{WGET}) : which('wget') };

sub init
{
  my($self, $meta) = @_;
  
  $meta->register_hook(
    fetch => sub {
      my($build, $url) = @_;
      $url ||= $meta->prop->{start_url};

      my($scheme) = $url =~ /^([a-z0-9]+):/i;
      
      if($scheme eq 'http')
      {
        local $CWD = tempdir( CLEANUP => 1 );
        
        my($stdout, $stderr) = $self->_execute(
          $build,
          $self->wget_command,
          '-k', '--content-disposition', '-S',
          $url,
        );

        my($path) = path('.')->children;
        die "no file found after wget" unless $path;
        my($type) = $stderr =~ /Content-Type:\s*(.*?)$/m;
        $type =~ s/;.*$// if $type;
        if($type eq 'text/html')
        {
          return {
            type    => 'html',
            base    => $url,
            content => scalar $path->slurp,
          };
        }
        else
        {
          return {
            type     => 'file',
            filename => $path->basename,
            path     => $path->absolute->stringify,
          };
        }
      }
      else
      {
        die "scheme $scheme is not supported by the Fetch::Wget plugin";
      }
    },
  ) if $self->wget_command;
}

sub _execute
{
  my($self, $build, @command) = @_;
  $build->log("+ @command");
  my($stdout, $stderr, $err) = capture {
    system @command;
    $?;
  };
  if($err)
  {
    chomp $stderr;
    $stderr = [split /\n/, $stderr]->[-1];
    die "error in wget fetch: $stderr";
  }
  ($stdout, $stderr);
}

1;
