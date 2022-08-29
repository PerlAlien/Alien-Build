use Test2::V0 -no_srand => 1;
use Config;

eval { require 'Test/More.pm' };

# This .t file is generated.
# make changes instead to dist.ini

my %modules;
my $post_diag;

$modules{$_} = $_ for qw(
  Acme::Alien::DontPanic
  Alien::Base::ModuleBuild
  Alien::Libbz2
  Alien::cmake3
  Alien::gzip
  Alien::xz
  Archive::Tar
  Archive::Zip
  Capture::Tiny
  Devel::Hide
  Digest::SHA
  Env::ShellWords
  ExtUtils::CBuilder
  ExtUtils::MakeMaker
  ExtUtils::ParseXS
  FFI::CheckLib
  FFI::Platypus
  File::Listing
  File::Listing::Ftpcopy
  File::Which
  File::chdir
  HTML::Parser
  HTTP::Tiny
  IO::Compress::Bzip2
  IO::Socket::SSL
  IO::Uncompress::Bunzip2
  IO::Zlib
  JSON::PP
  LWP
  LWP::Protocol::https
  List::Util
  Mojo::DOM58
  Mojolicious
  Net::FTP
  Net::SSLeay
  Path::Tiny
  PkgConfig
  PkgConfig::LibPkgConf
  Plack
  Readonly
  Sort::Versions
  Test2::API
  Test2::V0
  Text::ParseWords
  URI
  YAML
  parent
);

$post_diag = sub {
  eval {
    require Alien::Build::Plugin::Core::Setup;
    require Alien::Build::Plugin::Build::Autoconf;
    require Alien::Build::Plugin::Build::CMake;
    require Alien::Build::Plugin::PkgConfig::Negotiate;
    require Alien::Build::Util;
    require File::Which;
  };
  if($@)
  {
    diag "error: $@";
  }
  else
  {
    my %hash;
    Alien::Build::Plugin::Core::Setup->_platform(\%hash);
    $hash{cmake_generator} = Alien::Build::Plugin::Build::CMake::cmake_generator();
    $hash{'pkg-config'}->{$_} = File::Which::which($_) for qw( pkg-config pkgconf );
    $hash{'pkg-config'}->{PKG_CONFIG} = File::Which::which($ENV{PKG_CONFIG}) if defined $ENV{PKG_CONFIG};
    diag Alien::Build::Util::_dump(\%hash);
    diag "pkg-config negotiate pick = ", Alien::Build::Plugin::PkgConfig::Negotiate->pick;
    diag '';
    diag '';
    diag "[config.site]";
    diag(Alien::Build::Plugin::Build::Autoconf->new->config_site);
  }
};

my @modules = sort keys %modules;

sub spacer ()
{
  diag '';
  diag '';
  diag '';
}

pass 'okay';

my $max = 1;
$max = $_ > $max ? $_ : $max for map { length $_ } @modules;
our $format = "%-${max}s %s";

spacer;

my @keys = sort grep /(MOJO|PERL|\A(LC|HARNESS)_|\A(SHELL|LANG)\Z)/i, keys %ENV;

if(@keys > 0)
{
  diag "$_=$ENV{$_}" for @keys;

  if($ENV{PERL5LIB})
  {
    spacer;
    diag "PERL5LIB path";
    diag $_ for split $Config{path_sep}, $ENV{PERL5LIB};

  }
  elsif($ENV{PERLLIB})
  {
    spacer;
    diag "PERLLIB path";
    diag $_ for split $Config{path_sep}, $ENV{PERLLIB};
  }

  spacer;
}

diag sprintf $format, 'perl', "$] $^O $Config{archname}";

foreach my $module (sort @modules)
{
  my $pm = "$module.pm";
  $pm =~ s{::}{/}g;
  if(eval { require $pm; 1 })
  {
    my $ver = eval { $module->VERSION };
    $ver = 'undef' unless defined $ver;
    diag sprintf $format, $module, $ver;
  }
  else
  {
    diag sprintf $format, $module, '-';
  }
}

if($post_diag)
{
  spacer;
  $post_diag->();
}

spacer;

done_testing;

