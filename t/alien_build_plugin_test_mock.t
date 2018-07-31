use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Test::Mock;
use Path::Tiny qw( path );

subtest 'basic' => sub {
  alienfile_ok q{
    use alienfile;
    plugin 'Test::Mock';
  };
};

subtest 'probe' => sub {

  subtest 'share' => sub {
  
    alienfile_ok q{
      use alienfile;
      plugin 'Test::Mock' => (
        'probe' => 'share'
      );
    };
    
    alien_install_type_is 'share';
  
  };

  subtest 'share' => sub {
  
    alienfile_ok q{
      use alienfile;
      plugin 'Test::Mock' => (
        'probe' => 'system'
      );
    };
    
    alien_install_type_is 'system';
  
  };

  subtest 'share' => sub {
  
    alienfile_ok q{
      use alienfile;
      plugin 'Test::Mock' => (
        'probe' => 'die'
      );
    };
    
    alien_install_type_is 'share';
  
  };

};

subtest 'download' => sub {

  subtest 'default' => sub {
    my $build = alienfile_ok q{
      use alienfile;
      plugin 'Test::Mock' => (
        probe => 'share',
        download => 1,
      );
    };
    alien_download_ok;
    my $tarball = path($build->install_prop->{download});
    is(
      $tarball,
      object {
        call basename => 'foo-1.00.tar.gz';
        call slurp => path('corpus/dist/foo-1.00.tar.gz')->slurp;
      },
    );
  };

  subtest 'override' => sub {
    my $build = alienfile_ok q{
      use alienfile;
      plugin 'Test::Mock' => (
        download => { 'bar-1.00.tar.gz' => 'fauxtar' },
      );
    };
    alien_download_ok;
    my $tarball = path($build->install_prop->{download});
    is(
      $tarball,
      object {
        call basename => 'bar-1.00.tar.gz';
        call slurp => 'fauxtar';
      },
    );
  };

};

done_testing;
