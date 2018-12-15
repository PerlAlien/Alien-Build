use strict;
use warnings;

exit if $] < 5.010001;

my $exit = 0;

sub run
{
  print "% @_\n";
  system(@_);
  if($?)
  {
    $exit = 2;
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

exit $exit;
