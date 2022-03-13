package Alien::Build::Plugin::Probe::CommandLine;

use strict;
use warnings;
use 5.008004;
use Alien::Build::Plugin;
use Carp ();
use Capture::Tiny qw( capture );
use File::Which ();
use Alien::Util qw( version_cmp );

# ABSTRACT: Probe for tools or commands already available
# VERSION

=head1 SYNOPSIS

 use alienfile;
 plugin 'Probe::CommandLine' => (
   command => 'gzip',
   args    => [ '--version' ],
   match   => qr/gzip/,
   version => qr/gzip ([0-9\.]+)/,
 );

=head1 DESCRIPTION

This plugin probes for the existence of the given command line program.

=head1 PROPERTIES

=head2 command

The name of the command.

=cut

has '+command' => sub { Carp::croak "@{[ __PACKAGE__ ]} requires command property" };

=head2 args

The arguments to pass to the command.

=cut

has 'args'       => [];

=head2 secondary

If you are using another probe plugin (such as L<Alien::Build::Plugin::Probe::CBuilder> or
L<Alien::Build::Plugin::PkgConfig::Negotiate>) to detect the existence of a library, but
also need a program to exist, then you should set secondary to a true value.  For example
when you need both:

 use alienfile;
 # requires both liblzma library and xz program
 plugin 'PkgConfig' => 'liblzma';
 plugin 'Probe::CommandLine => (
   command   => 'xz',
   secondary => 1,
 );

When you don't:

 use alienfile;
 plugin 'Probe::CommandLine' => (
   command   => 'gzip',
   secondary => 0, # default
 );

=cut

has 'secondary' => 0;

=head2 match

Regular expression for which the program output should match.

=cut

has 'match'     => undef;

=head2 match_stderr

Regular expression for which the program standard error should match.

=cut

has 'match_stderr' => undef;

=head2 version

Regular expression to parse out the version from the program output.
The regular expression should store the version number in C<$1>.

=cut

has 'version'   => undef;

=head2 version_stderr

Regular expression to parse out the version from the program standard error.
The regular expression should store the version number in C<$1>.

=cut

has 'version_stderr' => undef;

=head2 atleast_version

The minimum required version as provided by the system.

=cut

has 'atleast_version' => undef;


sub init
{
  my($self, $meta) = @_;

  my $check = sub {
    my($build) = @_;

    unless(File::Which::which($self->command))
    {
      die 'Command not found ' . $self->command;
    }

    if(defined $self->match || defined $self->match_stderr || defined $self->version || defined $self->version_stderr)
    {
      my($out,$err,$ret) = capture {
        system( $self->command, @{ $self->args } );
      };
      die 'Command did not return a true value' if $ret;
      die 'Command output did not match' if defined $self->match && $out !~ $self->match;
      die 'Command standard error did not match' if defined $self->match_stderr && $err !~ $self->match_stderr;
      if (defined $self->version or defined $self->version_stderr)
      {
        my $found_version = '0';
        if(defined $self->version)
        {
          if($out =~ $self->version)
          {
            $found_version = $1;
            $build->runtime_prop->{version} = $found_version;
          }
        }
        if(defined $self->version_stderr)
        {
          if($err =~ $self->version_stderr)
          {
            $found_version = $1;
            $build->hook_prop->{version} = $found_version;
            $build->runtime_prop->{version} = $found_version;
          }
        }
        if (my $atleast_version = $self->atleast_version)
        {
          if(version_cmp ($found_version, $self->atleast_version) < 0)
          {
            #  reset the versions
            $build->runtime_prop->{version} = undef;
            $build->hook_prop->{version} = undef;
            die "CommandLine probe found version $found_version, but at least $atleast_version is required.";
          }
        }
      }
    }

    $build->runtime_prop->{command} = $self->command;
    'system';
  };

  if($self->secondary)
  {
    $meta->around_hook(
      probe => sub {
        my $orig = shift;
        my $build = shift;
        my $type = $orig->($build, @_);
        return $type unless $type eq 'system';
        $check->($build);
      },
    );
  }
  else
  {
    $meta->register_hook(
      probe => $check,
    );
  }
}

1;

=head1 SEE ALSO

L<Alien::Build>, L<alienfile>, L<Alien::Build::MM>, L<Alien>

=cut
