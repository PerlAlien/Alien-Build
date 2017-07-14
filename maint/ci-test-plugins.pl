use strict;
use warnings;

exit if $] < 5.010;

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

my @mods = (
  Alien::Build::MB
  Alien::Build::Plugin::Fetch::Cache
  Alien::Build::Plugin::Fetch::Prompt
  Alien::Build::Plugin::Fetch::Rewrite
  Alien::Build::Plugin::Probe::GnuWin32
);

foreach my $mod (@mods)
{
  run 'cpanm', '--installdeps', '-n', $mod;
  run 'cpanm', '--reinstall', '-v', $mod;
}

exit $exit;
