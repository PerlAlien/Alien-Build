use strict;
use warnings;
use Config;
use Test::More tests => 1;

# This .t file is generated.
# make changes instead to dist.ini

my %modules;
my $post_diag;

$modules{$_} = $_ for qw(
  Acme::Alien::DontPanic
  Alien::Base
  Alien::Libarchive
  Capture::Tiny
  ExtUtils::CBuilder
  ExtUtils::MakeMaker
  ExtUtils::ParseXS
  FFI::CheckLib
  FFI::Platypus
  File::Listing
  File::Listing::Ftpcopy
  File::Which
  File::chdir
  HTML::LinkExtor
  HTTP::Tiny
  IPC::Cmd
  JSON::PP
  LWP
  Module::Load
  Net::FTP
  Path::Tiny
  PkgConfig
  PkgConfig::LibPkgConf
  Sort::Versions
  Test2::API
  Test2::Mock
  Test2::Require
  Test2::Require::Module
  Test2::V0
  Test::More
  Text::ParseWords
  URI
  YAML
);



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

diag sprintf $format, 'perl ', $];

foreach my $module (@modules)
{
  if(eval qq{ require $module; 1 })
  {
    my $ver = eval qq{ \$$module\::VERSION };
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

