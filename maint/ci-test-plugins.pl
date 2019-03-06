use strict;
use warnings;

exit if $] < 5.010001;

my $exit = 0;

my @fails;

sub run
{
  print "% @_\n";
  system(@_);
  if($?)
  {
    push @fails, [@_];
    warn "command failed!";
  }
}

my @mods = qw(
  Alien::Build::MB
  Alien::Build::Plugin::Build::Premake5
  Alien::Build::Plugin::Decode::SourceForge
  Alien::Build::Plugin::Probe::Override
  Alien::Build::Plugin::Fetch::Prompt
  Alien::Build::Plugin::Fetch::Rewrite
);

foreach my $mod (@mods)
{
  run 'cpanm', '--installdeps', '-n', $mod;
  run 'cpanm', '--reinstall', '-v', $mod;
}

if(@fails)
{
  print "failure summary:\n";
  print "+@{[ @$_ ]}" for @fails;
  exit 2;
}
