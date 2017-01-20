package MyTest::System;

use strict;
use warnings;
use base qw( Exporter );

our @EXPORT = qw( system_last system_clear system_hook );

my %commands;
my @command_list;

*CORE::GLOBAL::system = sub {
  push @command_list, [@_];
  if($commands{$_[0]})
  {
    $commands{$_[0]}->(@_);
  }
  $? = $_[0] eq 'bogus' ? -1 : 0;
};

sub system_last
{
  \@command_list;
}

sub system_clear
{
  @command_list = ();
}

sub system_hook
{
  my($name, $code) = @_;
  $commands{$name} = $code;
}

1;


