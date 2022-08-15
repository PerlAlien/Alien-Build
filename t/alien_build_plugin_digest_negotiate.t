use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Path::Tiny qw( path );

our $download_filename;

subtest 'basic' => sub {

  local $Alien::Build::VERSION = 2.57;

  my $build = alienfile_ok q{
    use alienfile;
    probe sub { 'share' };

    share {
      plugin 'Digest' => [ SHA256 => 'a7e79996a02d3dfc47f6f3ec043c67690dc06a10d091bf1d760fee7c8161391a' ];
      plugin 'Fetch::Local';
      download sub {
        $main::download_filename->copy($main::download_filename->basename);
      };
    };
  };

  is
    $build->meta->prop->{check_digest},
    T(),
    'set meta.check_digest flag';

  alienfile_skip_if_missing_prereqs;

  subtest 'check_digest method' => sub {

    is
      $build->check_digest('corpus/alien_build_plugin_digest_shapp/foo.txt.gz'),
      T(),
      'check digest works';

    is
      dies { $build->check_digest(__FILE__) },
      match qr/SHA256 digest does not match/,
      'check digest throws exception on bad signature';
  };

  subtest 'fetch method' => sub {

    is
      $build->fetch('corpus/alien_build_plugin_digest_shapp/foo.txt.gz'),
      hash {
        field type => 'file';
        field filename => 'foo.txt.gz';
        etc;
      },
      'fetch works with right signature';

    is
      dies { $build->fetch(__FILE__) },
      match qr/SHA256 digest does not match/,
      'fetch dies with wrong signature';

  };

  subtest 'download method' => sub {

    local $download_filename = path('corpus/alien_build_plugin_digest_shapp/foo.txt.gz')->absolute;

    is
      $build,
      object {
        call download => T();
        call install_prop => hash {
          field download => match qr/foo.txt.gz/;
          etc;
        };
      },
      'download works with right signature';

    delete $build->install_prop->{complete};
    delete $build->install_prop->{download};
    $download_filename = path(__FILE__)->absolute;

    is
      dies { $build->download },
      match qr/SHA256 digest does not match/,
      'download dies with wrong signature';
  };

};

subtest 'two signatures' => sub {

  local $Alien::Build::VERSION = 2.57;

  my $build = alienfile_ok q{
    use alienfile;
    probe sub { 'share' };

    share {
      plugin 'Digest' => {
        'foo.txt.gz'                            => [ SHA256 => 'a7e79996a02d3dfc47f6f3ec043c67690dc06a10d091bf1d760fee7c8161391a' ],
        'foo.txt'                               => [ SHA256 => '032772271db8f134e4914bca0e933361e1946c91c21e43610d301d39cbdb9d51' ],
        'alien_build_plugin_digest_negotiate.t' => [ SHA256 => 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' ],
      };
      plugin 'Fetch::Local';
      download sub {
        $main::download_filename->copy($main::download_filename->basename);
      };
    };
  };

  alienfile_skip_if_missing_prereqs;

  subtest 'check_digest method' => sub {

    is
      $build->check_digest('corpus/alien_build_plugin_digest_shapp/foo.txt.gz'),
      T(),
      'check digest works foo.txt.gz';

    is
      $build->check_digest('corpus/alien_build_plugin_digest_shapp/foo.txt'),
      T(),
      'check digest works foo.txt';

    is
      dies { $build->check_digest(__FILE__) },
      match qr/SHA256 digest does not match/,
      'check digest throws exception on bad signature';
  };

  subtest 'fetch method' => sub {

    is
      $build->fetch('corpus/alien_build_plugin_digest_shapp/foo.txt.gz'),
      hash {
        field type => 'file';
        field filename => 'foo.txt.gz';
        etc;
      },
      'fetch works foo.txt.gz';

    is
      $build->fetch('corpus/alien_build_plugin_digest_shapp/foo.txt'),
      hash {
        field type => 'file';
        field filename => 'foo.txt';
        etc;
      },
      'fetch works foo.txt';

    is
      dies { $build->fetch(__FILE__) },
      match qr/SHA256 digest does not match/,
      'fetch throws exception on bad signature';

  };

  subtest 'download method' => sub {

    local $download_filename = path('corpus/alien_build_plugin_digest_shapp/foo.txt')->absolute;

    is
      $build,
      object {
        call download => T();
        call install_prop => hash {
          field download => match qr/foo.txt/;
          etc;
        };
      },
      'download works with right signature';

    delete $build->install_prop->{download};
    delete $build->install_prop->{complete};
    $download_filename = path('corpus/alien_build_plugin_digest_shapp/foo.txt.gz')->absolute;

    is
      $build,
      object {
        call download => T();
        call install_prop => hash {
          field download => match qr/foo.txt.gz/;
          etc;
        };
      },
      'download works with right signature';

    delete $build->install_prop->{download};
    delete $build->install_prop->{complete};
    $download_filename = path(__FILE__)->absolute;

    is
      dies { $build->download },
      match qr/SHA256 digest does not match/,
      'download dies with wrong signature';
  };

};

done_testing;
