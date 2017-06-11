use strict;
use warnings;
use ExtUtils::MakeMaker;
use Alien::Base::Wrapper qw( Alien::xz );

WriteMakefile(
  NAME               => 'LZMA::Example',
  VERSION_FROM       => 'lib/LZMA/Example.pm',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => 6.52,
    'Alien::xz'           => '0.05',
  },
  Alien::Base::Wrapper->mm_args,
);
