use lib 'corpus/lib';
use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Prefer::GoodVersion;
use Path::Tiny qw( path );

eval { require Sort::Versions };
skip_all 'test requires Sort::Versions' if $@;

$Alien::Build::Plugin::Prefer::GoodVersion::VERSION ||= '1.44';

subtest 'compiles okay' => sub {

  alienfile_ok q{
    use alienfile;
    plugin 'Prefer::GoodVersion' => '1.2.3';
  };

};

subtest 'filter is required' => sub {

  eval {
    alienfile q{
      use alienfile;
      plugin 'Prefer::GoodVersion';
    }
  };

  like $@, qr/The filter property is required for the Prefer::GoodVersion plugin/;

};

subtest 'filters out string version' => sub {

  alienfile_ok q{
    use alienfile;
    share {
      plugin 'Fetch::Foo' => [ qw( 1.2.3 1.2.4 1.2.5 ) ];
      plugin 'Prefer::SortVersions';
      plugin 'Prefer::GoodVersion' => '1.2.4';
    };
  };

  my $file = alien_download_ok;
  is(path($file)->slurp_raw, "data:foo-1.2.4.tar.gz");

};

subtest 'filters out list version' => sub {

  alienfile_ok q{
    use alienfile;
    share {
      plugin 'Fetch::Foo' => [ qw( 1.2.3 1.2.4 1.2.5 ) ];
      plugin 'Prefer::SortVersions';
      plugin 'Prefer::GoodVersion' => ['1.2.4', '1.2.3'];
    };
  };

  my $file = alien_download_ok;
  is(path($file)->slurp_raw, "data:foo-1.2.4.tar.gz");

};

subtest 'filters out code ref' => sub {

  alienfile_ok q{
    use alienfile;
    share {
      plugin 'Fetch::Foo' => [ qw( 1.2.3 1.2.4 1.2.5 ) ];
      plugin 'Prefer::SortVersions';
      plugin 'Prefer::GoodVersion' => sub {
        my($file) = @_;
        $file->{version} eq '1.2.4';
      };
    };
  };

  my $file = alien_download_ok;
  is(path($file)->slurp_raw, "data:foo-1.2.4.tar.gz");


};

done_testing;
