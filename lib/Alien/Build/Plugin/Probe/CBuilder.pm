package Alien::Build::Plugin::Probe::CBuilder;

use strict;
use warnings;
use Alien::Build::Plugin;
use File::chdir;
use File::Temp ();
use Capture::Tiny qw( capture_merged capture );

# ABSTRACT: Probe for system libraries by guessing with ExtUtils::CBuilder
# VERSION

has options => {};
has cflags  => '';
has libs    => '';
has program => 'int main(int argc, char *argv[]) { return 0; }';
has version => undef;

sub init
{
  my($self, $meta) = @_;
  
  $meta->add_requires('configure' => 'ExtUtils::CBuilder' => 0 );
  
  $meta->register_hook(
    probe => sub {
      my($build) = @_;
      local $CWD = File::Temp::tempdir( CLEANUP => 1 );
      
      open my $fh, '>', 'mytest.c';
      print $fh $self->program;
      close $fh;
      
      print "Alien::Build::Plugin::Probe::CBuilder> trying: cflags=@{[ $self->cflags ]} libs=@{[ $self->libs ]}\n";
      
      my $b = ExtUtils::CBuilder->new(%{ $self->options });

      my($out1, $obj) = capture_merged {
        $b->compile(
          source               => 'mytest.c',
          extra_compiler_flags => $self->cflags,
        );
      };
      
      my($out2, $exe) = capture_merged {
        $b->link_executable(
          objects              => [$obj],
          extra_linker_flags   => $self->libs,
        );
      };
      
      my($out, $err, $ret) = capture { system($^O eq 'MSWin32' ? $exe : "./$exe") };
      die "execute failed" if $ret;
      
      if(defined $self->version)
      {
        ($build->runtime_prop->{version}) = $out =~ $self->version;
      }
      
      my $cflags = $self->cflags;
      my $libs   = $self->libs;
      
      $cflags =~ s{\s*$}{ };
      $libs =~ s{\s*$}{ };
      
      $build->runtime_prop->{cflags} = $cflags;
      $build->runtime_prop->{libs}   = $libs;
      
      'system';
    }
  );
}

1;
