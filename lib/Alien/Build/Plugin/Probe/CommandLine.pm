package Alien::Build::Plugin::Probe::CommandLine;

use strict;
use warnings;
use Alien::Build::Plugin;
use Carp ();
use Capture::Tiny qw( capture );

# ABSTRACT: Probe for tools or commands already available
# VERSION

has '+command' => sub { Carp::croak "@{[ __PACKAGE__ ]} requires command property" };
has 'args'       => [];
has 'secondary' => 0;
has 'match'     => undef;
has 'version'   => undef;

sub init
{
  my($self, $meta) = @_;
  
  # in core as of 5.10, but still need it for 5.8
  # apparently.
  $meta->add_requires( 'configure' => 'IPC::Cmd' => 0 );
  
  my $check = sub {
    my($build) = @_;

    $DB::single = 1;

    unless(IPC::Cmd::can_run($self->command))
    {
      return 'share';
    }

    if(defined $self->match || defined $self->version)
    {
      my($out,$err,$ret) = capture {
        system( $self->command, @{ $self->args } );
      };
      return 'share' if $ret;
      return 'share' if defined $self->match && $out !~ $self->match;
      if(defined $self->version)
      {
        if($out =~ $self->version)
        {
          $build->runtime_prop->{version} = $1;
        }
      }
    }

    $build->runtime_prop->{command} = $self->command if $build;
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
