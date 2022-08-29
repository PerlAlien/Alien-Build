use strict;
use warnings;
use File::Glob qw( bsd_glob );

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

my(@tarball) = bsd_glob 'Alien-Build-*.tar.gz';
die "not exactly one tarball: @tarball" if @tarball != 1;
my $tarball = shift @tarball;
run 'cpanm', '-n', $tarball;

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
  {
    local $ENV{ALIEN_DOWNLOAD_RULE} = 'default';
    local $ENV{ALIEN_INSTALL_TYPE} = 'default';
    run 'cpanm', '--installdeps', '-n', $mod;
  }
  run 'cpanm', '--reinstall', '-v', $mod;
}

if(@fails)
{
  print "failure summary:\n";
  print "+@{[ @$_ ]}" for @fails;
  exit 2;
}
