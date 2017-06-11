use strict;
use warnings;
use Module::Build;
use Alien::xz;

my $build = Module::Build->new(
  module_name => 'LZMA::Example',
  dist_abstract => 'lzma example',
  configure_requires => {
    'Alien::xz' => '0.05',
  },
  extra_compiler_flags => Alien::xz->cflags,
  extra_linker_flags   => Alien::xz->libs,
);

$build->create_build_script;

