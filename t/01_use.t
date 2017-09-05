use Test2::V0 -no_srand => 1;

sub require_ok ($);

require_ok 'Alien::Base';
require_ok 'Alien::Base::Wrapper';
require_ok 'Alien::Build';
require_ok 'Alien::Build::CommandSequence';
require_ok 'Alien::Build::Interpolate';
require_ok 'Alien::Build::Interpolate::Default';
require_ok 'Alien::Build::MM';
require_ok 'Alien::Build::Plugin';
require_ok 'Alien::Build::Plugin::Build::Autoconf';
require_ok 'Alien::Build::Plugin::Build::CMake';
require_ok 'Alien::Build::Plugin::Build::MSYS';
require_ok 'Alien::Build::Plugin::Build::Make';
require_ok 'Alien::Build::Plugin::Build::SearchDep';
require_ok 'Alien::Build::Plugin::Core::Download';
require_ok 'Alien::Build::Plugin::Core::FFI';
require_ok 'Alien::Build::Plugin::Core::Gather';
require_ok 'Alien::Build::Plugin::Core::Legacy';
require_ok 'Alien::Build::Plugin::Core::Override';
require_ok 'Alien::Build::Plugin::Core::Setup';
require_ok 'Alien::Build::Plugin::Core::Tail';
require_ok 'Alien::Build::Plugin::Decode::DirListing';
require_ok 'Alien::Build::Plugin::Decode::DirListingFtpcopy';
require_ok 'Alien::Build::Plugin::Decode::HTML';
require_ok 'Alien::Build::Plugin::Download::Negotiate';
require_ok 'Alien::Build::Plugin::Extract::ArchiveTar';
require_ok 'Alien::Build::Plugin::Extract::ArchiveZip';
require_ok 'Alien::Build::Plugin::Extract::CommandLine';
require_ok 'Alien::Build::Plugin::Extract::Directory';
require_ok 'Alien::Build::Plugin::Extract::Negotiate';
require_ok 'Alien::Build::Plugin::Fetch::HTTPTiny';
require_ok 'Alien::Build::Plugin::Fetch::LWP';
require_ok 'Alien::Build::Plugin::Fetch::Local';
require_ok 'Alien::Build::Plugin::Fetch::LocalDir';
require_ok 'Alien::Build::Plugin::Fetch::NetFTP';
require_ok 'Alien::Build::Plugin::Gather::IsolateDynamic';
require_ok 'Alien::Build::Plugin::PkgConfig::CommandLine';
require_ok 'Alien::Build::Plugin::PkgConfig::LibPkgConf';
require_ok 'Alien::Build::Plugin::PkgConfig::MakeStatic';
require_ok 'Alien::Build::Plugin::PkgConfig::Negotiate';
require_ok 'Alien::Build::Plugin::PkgConfig::PP';
require_ok 'Alien::Build::Plugin::Prefer::BadVersion';
require_ok 'Alien::Build::Plugin::Prefer::SortVersions';
require_ok 'Alien::Build::Plugin::Probe::CBuilder';
require_ok 'Alien::Build::Plugin::Probe::CommandLine';
require_ok 'Alien::Build::Util';
require_ok 'Alien::Build::Util::Win32::RegistryDump';
require_ok 'Alien::Role';
require_ok 'Test::Alien';
require_ok 'Test::Alien::Build';
require_ok 'Test::Alien::CanCompile';
require_ok 'Test::Alien::CanPlatypus';
require_ok 'Test::Alien::Run';
require_ok 'Test::Alien::Synthetic';
require_ok 'alienfile';
done_testing;

sub require_ok ($)
{
  # special case of when I really do want require_ok.
  # I just want a test that checks that the modules
  # will compile okay.  I won't be trying to use them.
  my($mod) = @_;
  my $ctx = context();
  eval qq{ require $mod };
  my $error = $@;
  my $ok = !$error;
  $ctx->ok($ok, "require $mod");
  $ctx->diag("error: $error") if $error ne '';
  $ctx->release;
}
