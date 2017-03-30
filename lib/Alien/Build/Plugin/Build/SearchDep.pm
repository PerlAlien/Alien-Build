package Alien::Build::Plugin::Build::SearchDep;

use strict;
use warnings;
use Alien::Build::Plugin;
use Text::ParseWords qw( shellwords );

# ABSTRACT: Add dependencies to library and header search path
# VERSION

our $VERSION = '0.35';

=head1 SYNOPSIS

 use alienfile;
 plugin 'Build::SearchDep' => (
   aliens => [qw( Alien::Foo Alien::Bar )],
 );

=head1 DESCRIPTION

This plugin adds the other aliens as prerequsites, and adds their header and library
search path to C<CFLAGS> and C<LDFLAGS> environment variable, so that tools that use
them (like autoconf) can pick them up.

=head1 PROPERTIES

=head2 aliens

Either a list reference or hash reference of the other aliens.  If a hash reference
then the keys are the class names and the valuess are the versions of those classes.

=cut

has aliens => {};

sub init
{
  my($self, $meta) = @_;
  
  $meta->add_requires('configure' => 'Alien::Build::Plugin::Build::SearchDep' => '0.34');
  $meta->add_requires('share'     => 'Env::ShellWords' => 0.01);
  
  my @aliens;
  if(ref($self->aliens) eq 'HASH')
  {
    @aliens = keys %{ $self->aliens };
    $meta->add_requires('share' => $_ => $self->aliens->{$_}) for @aliens;
  }
  else
  {
    @aliens = ref $self->aliens ? @{ $self->aliens } : ($self->aliens);
    $meta->add_requires('share' => $_ => 0) for @aliens;
  }
  
  $meta->around_hook(
    build => sub {
      my($orig, $build) = @_;
      
      local $ENV{CFLAGS} = $ENV{CFLAGS};
      local $ENV{LDFLAGS} = $ENV{LDFLAGS};
      
      tie my @CFLAGS,  'Env::ShellWords', 'CFLAGS';
      tie my @LDFLAGS, 'Env::ShellWords', 'LDFLAGS';
      
      my $cflags = [];
      my $ldflags = $build->install_prop->{plugin_build_searchdep_ldflags} = [];
      
      foreach my $other (@aliens)
      {
        my $other_cflags;
        my $other_libs;
        if($other->install_type('share'))
        {
          $other_cflags = $other->cflags_static;
          $other_libs   = $other->libs_static;
        }
        else
        {
          $other_cflags = $other->cflags;
          $other_libs   = $other->libs;
        }
        unshift @$cflags,  grep /^-I/, shellwords($other_cflags);
        unshift @$ldflags, grep /^-L/, shellwords($other_libs);
      }
      
      unshift @CFLAGS, @$cflags;
      unshift @LDFLAGS, @$ldflags;
      
      $orig->($build);
      
    },
  );
  
  $meta->after_hook(
    gather_share => sub {
      my($build) = @_;
      
      $build->runtime_prop->{$_} = join(' ', @{ $build->install_prop->{plugin_build_searchdep_ldflags} }) . ' ' . $build->runtime_prop->{$_}
        for qw( libs libs_static );
    },
  );
}

1;
