use strict;
use warnings;
use ExtUtils::MakeMaker;
use Alien::Build::MM;

my $abmm = Alien::Build::MM->new;

my %args = $abmm->mm_args(
  ABSTRACT         => 'Discover or download and install xz + liblzma',
  AUTHOR           => [ 'Graham Ollis <plicease@cpan.org>' ],
  DISTNAME         => 'Alien-xz',
  LICENSE          => 'perl',
  MIN_PERL_VERSION => '5.008001',
  NAME             => 'Alien::xz',
  VERSION_FROM     => 'lib/Alien/xz.pm',
);

WriteMakefile(%args);

sub MY::postamble {

  $abmm->mm_postamble;

}
