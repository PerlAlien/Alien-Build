use 5.008004;
use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Fetch::LocalDir;
use Capture::Tiny qw( capture_merged );
use Path::Tiny qw( path );

subtest 'basic' => sub {

  local $Alien::Build::Plugin::Fetch::LocalDir::VERSION = $Alien::Build::Plugin::Fetch::LocalDir::VERSION || 2.57;

  my $build = alienfile_ok q{
    use alienfile;

    probe sub { 'share' };

    share {

      meta->prop->{start_url} = 'corpus/dist/foo-1.00/';
      plugin 'Fetch::LocalDir';
      plugin 'Extract' => format => 'd';

    };
  };

  alienfile_skip_if_missing_prereqs;
  alien_install_type_is 'share';
  alien_download_ok;

  my $download = $build->install_prop->{download};

  ok -d $download, 'download is a directory';
  note "download = $download";

  ok -f path($download)->child('configure'), 'configure is a file';
  ok -f path($download)->child('foo.c'),     'foo.c is a file';

  alien_extract_ok;
};

done_testing;
