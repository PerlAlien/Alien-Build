package Alien::Build::Plugin::Probe::CBuilder;

use strict;
use warnings;
use Alien::Build::Plugin;
use File::chdir;
use File::Temp ();
use Capture::Tiny qw( capture_merged capture );

# ABSTRACT: Probe for system libraries by guessing with ExtUtils::CBuilder
# VERSION

=head1 SYNOPSIS

 use alienfile;
 plugin 'Probe::CBuilder' => (
   cflags => '-I/opt/libfoo/include',
   libs   => '-L/opt/libfoo/lib -lfoo',
 );

=head1 DESCRIPTION

This plugin probes for compiler and linker flags using L<ExtUtils::CBuilder>.  This is a useful
alternative to L<Alien::Build::Plugin::PkgConfig::Negotiate> for packages that do not provide
a pkg-config C<.pc> file, or for when those C<.pc> files may not be available.  (For example,
on FreeBSD, C<libarchive> is a core part of the operating system, but doesn't include a C<.pc>
file which is usually provided when you install the C<libarchive> package on Linux).

=head1 PROPERTIES

=head2 options

Any extra options that you want to have passed into the constructor to L<ExtUtils::CBuilder>.

=cut

has options => sub { {} };

=head2 cflags

The compiler flags.

=cut

has cflags  => '';

=head2 libs

The linker flags

=cut

has libs    => '';

=head2 program

The program to use in the test.

=cut

has program => 'int main(int argc, char *argv[]) { return 0; }';

=head2 version

This is a regular expression to parse the version out of the output from the
test program.

=cut

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
      
      $build->log("trying: cflags=@{[ $self->cflags ]} libs=@{[ $self->libs ]}");
      
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

=head1 SEE ALSO

L<Alien::Build>, L<alienfile>, L<Alien::Build::MM>, L<Alien>

=cut
