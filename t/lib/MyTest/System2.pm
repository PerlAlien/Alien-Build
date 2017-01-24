package MyTest::System2;

use strict;
use warnings;
use base qw( Exporter );
use Scalar::Util qw( refaddr );
use Text::ParseWords qw( shellwords );
use Scalar::Util qw( weaken );

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

sub DESTROY
{
  my($self) = @_;
  @stack = grep { refaddr($_) ne refaddr($self) } @stack;
}

1;
