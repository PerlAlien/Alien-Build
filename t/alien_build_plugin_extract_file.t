use 5.008004;
use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Extract::File;
use Path::Tiny qw( path );
use Capture::Tiny qw( capture_merged );

subtest 'handles' => sub {

  is(
    Alien::Build::Plugin::Extract::File->handles('f'),
    T(),
  );

  is(
    Alien::Build::Plugin::Extract::File->handles('tar'),
    F(),
  );

};

subtest 'available' => sub {

  is(
    Alien::Build::Plugin::Extract::File->available('f'),
    T(),
  );

  is(
    Alien::Build::Plugin::Extract::File->available('tar'),
    F(),
  );

};

subtest 'basic' => sub {

  local $Alien::Build::VERSION = $Alien::Build::VERSION || '2.70';

  my $build = alienfile_ok q{
    use alienfile;
    use Path::Tiny qw( path );
    plugin 'Test::Mock' => (
      probe => 'share',
      download => {
        "frooble.exe" => 'a faux exe',
      },
    );
    plugin 'Extract::File';
  };

  alien_install_type_is 'share';
  alien_download_ok;
  alien_extract_ok;

};

done_testing;
