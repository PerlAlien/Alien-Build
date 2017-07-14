use strict;
use warnings;

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

run 'cpanm', '--reinstall', '-v', $_ for qw(
  Alien::Build::MB
  Alien::Build::Plugin::Fetch::Cache
  Alien::Build::Plugin::Fetch::Prompt
  Alien::Build::Plugin::Fetch::Rewrite
  Alien::Build::Plugin::Probe::GnuWin32
);

exit $exit;
