package MyTest::System;

use strict;
use warnings;
use base qw( Exporter );
use Scalar::Util qw( refaddr );
use Text::ParseWords qw( shellwords );
use Scalar::Util qw( weaken );
use File::Which ();

our @EXPORT = qw( system_fake system_add );

sub system_fake
{
  __PACKAGE__->new(@_);
}

my @stack;

*CORE::GLOBAL::system = sub {

  my $system = $stack[-1];

  if($system)
  {
    $system->call(@_);
  }
  else
  {
    return CORE::system(@_);
  }

};

{
  my $old = \&File::Which::which;
  no warnings 'redefine';
  *File::Which::which = sub 
  {
    my $system = $stack[-1];
    
    if($system)
    {
      $system->can_run(@_);
    }
    else
    {
      return $old->(@_);
    }
  };
}

sub new
{
  my($class, %cmds) = @_;
  my $self = bless { %cmds }, $class;
  push @stack, $self;
  weaken $stack[-1];
  $self;
}

sub add
{
  my($self, $command, $code) = @_;
  $self->{$command} = $code;
}

sub call
{
  my($self, $command, @args) = @_;
  
  if(@args == 0)
  {
    if($^O eq 'MSWin32' && $command =~ /^"(.*)"$/)
    { $command = $1 }
    ($command, @args) = shellwords $command;
  }
  
  if($self->{$command})
  {
    my $exit = $self->{$command}->(@args);
    return $? = ($exit << 8);
  }
  else
  {
    $! = 'No such file or directory';
    return $? = -1;
  }
}

sub can_run
{
  my($self, $command) = @_;

  # we only really use can_run to figure out if
  # we CAN run an executable, but make up some
  # path just for pretends.  
  $self->{$command}
  ? "/bin/$command"
  : undef;
}

sub DESTROY
{
  my($self) = @_;
  @stack = grep { refaddr($_) ne refaddr($self) } @stack;
}

1;
