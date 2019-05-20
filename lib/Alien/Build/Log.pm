package Alien::Build::Log;

use strict;
use warnings;
use 5.008001;
use Carp ();

my $log_class;
my $self;

sub set_log_class
{
  (undef, $log_class) = @_;
  undef $self;
}

sub new
{
  my($class) = @_;

  $self || do {
    if($class eq 'Alien::Build::Log')
    {
      $class = $log_class || $ENV{ALIEN_BUILD_LOG} || 'Alien::Build::Log::Default';
      my $pm = "$class.pm";
      $pm =~ s/::/\//g;
      require $pm;
    }
    $self = bless {}, $class;
  };
}

sub log
{
  Carp::croak("AB Log base class");
}

1;
