use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => "Alien::Base::PkgConfig",
  VERSION_FROM => "lib/Alien/Base/PkgConfig.pm",
  PREREQ_PM    => {
    'Capture::Tiny' => 0,
    'Path::Tiny'    => 0,
  },
);
