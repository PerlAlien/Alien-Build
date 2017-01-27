package Alien::Build::MM;

use strict;
use warnings;
use Alien::Build;
use Path::Tiny ();
use Carp ();

# ABSTRACT: Alien::Build installer code for ExtUtils::MakeMaker
# VERSION

sub _path { goto \&Path::Tiny::path };

=head1 CONSTRUCTOR

=head2 new

 my $mm = Alien::Build::MM->new;

=cut

sub new
{
  my($class) = @_;
  
  my $self = bless {}, $class;
  
  $self->{build} =
    Alien::Build->load('alienfile',
      root     => "_alien",
      autosave => 1,
    )
  ;
  
  $self->build->load_requires('configure');
  $self->build->root;

  $self;
}

=head1 PROPERTIES

=head2 build

 my $build = $mm->build;

=cut

sub build
{
  shift->{build};
}

=head1 METHODS

=head2 mm_args

 my %args = $mm->mm_args(%args);

=cut

sub mm_args
{
  my($self, %args) = @_;
  
  if($args{DISTNAME})
  {
    $self->build->install_prop->{stage} = _path("blib/lib/auto/share/$args{DISTNAME}")->absolute->stringify;
  }
  else
  {
    Carp::croak "DISTNAME is required";
  }
  
  $args{CONFIGURE_REQUIRES} = Alien::Build::_merge(
    %{ $args{CONFIGURE_REQUIRES} },
    %{ $self->build->requires('configure') || {} },
  );

  if($self->build->install_type eq 'system')
  {
    $args{BUILD_REQUIRES} = Alien::Build::_merge(
      %{ $args{BUILD_REQUIRES} },
      %{ $self->build->requires('system') || {} },
    );
  }
  else # share
  {
    $args{BUILD_REQUIRES} = Alien::Build::_merge(
      %{ $args{BUILD_REQUIRES} },
      %{ $self->build->requires('share') || {} },
    );
  }
  
  %args;
}

sub mm_postamble
{
  my($self) = @_;
  
  my $postamble = '';
  
  $postamble;
}

sub import
{
  my(undef, @args) = @_;
  foreach my $arg (@args)
  {
    if($arg eq 'cmds')
    {
      package main;
      
      sub _args
      {
        (Alien::Build->resume('alienfile', '_alien'), @ARGV)
      }
      
      sub set_prefix
      {
        my($build, $prefix) = @_;
        $prefix = Path::Tiny->new($prefix)->absolute->stringify;
        if($build->meta_prop->{destdir})
        {
          $build->runtime_prop->{prefix} = 
          $build->install_prop->{prefix} = $prefix;
        }
        else
        {
          $build->runtime_prop->{prefix} = $prefix;
          $build->install_prop->{prefix} = $build->install_prop->{stage};
        }
        $build->checkpoint;
      }
      
      sub build
      {
        my($build) = @_;
        
        $build->load_requires('configure');
        $build->load_requires($build->install_type);
        
        if($build->install_type eq 'share')
        {
          $build->download;
          $build->build;
        }
        
        elsif($build->install_type eq 'system')
        {
          $build->gather_system;
        }
      }
    }
  }
}

1;
