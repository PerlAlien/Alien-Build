use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Fetch::LocalDir;
use Capture::Tiny qw( capture_merged );
use Path::Tiny qw( path );

my $build = alienfile_ok q{
  use alienfile;
  
  probe sub { 'share' };
  
  share {
  
    meta->prop->{start_url} = 'corpus/dist/foo-1.00/';
    plugin 'Fetch::LocalDir';
  
  };
};

my $error;

note scalar capture_merged {
  eval { $build->download };
  $error = $@;
};

is $error, '', 'did not throw exception';

my $download = $build->install_prop->{download};

ok -d $download, 'download is a directory';
note "download = $download";

ok -f path($download)->child('configure'), 'configure is a file';
ok -f path($download)->child('foo.c'),     'foo.c is a file';

done_testing;
