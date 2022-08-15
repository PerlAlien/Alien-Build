use Test2::V0 -no_srand => 1;
use Test::Alien::Build;

subtest 'basic' => sub {

  local $Alien::Build::VERSION = 2.57;

  my $build = alienfile_ok q{
    use alienfile;
    plugin 'Digest' => [ SHA256 => 'a7e79996a02d3dfc47f6f3ec043c67690dc06a10d091bf1d760fee7c8161391a' ];
    probe sub { 'share' };
  };

  is
    $build->meta->prop->{check_digest},
    T(),
    'set meta.check_digest flag';

  alienfile_skip_if_missing_prereqs;

  is
    $build->check_digest('corpus/alien_build_plugin_digest_shapp/foo.txt.gz'),
    T(),
    'check digest works';

  is
    dies { $build->check_digest(__FILE__) },
    match qr/SHA256 digest does not match/,
    'check digest throws exception on bad signature';

};

subtest 'two signatures' => sub {

  local $Alien::Build::VERSION = 2.57;

  my $build = alienfile_ok q{
    use alienfile;
    plugin 'Digest' => {
      'foo.txt.gz'                            => [ SHA256 => 'a7e79996a02d3dfc47f6f3ec043c67690dc06a10d091bf1d760fee7c8161391a' ],
      'foo.txt'                               => [ SHA256 => '032772271db8f134e4914bca0e933361e1946c91c21e43610d301d39cbdb9d51' ],
      'alien_build_plugin_digest_negotiate.t' => [ SHA256 => 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' ],
    };
    probe sub { 'share' };
  };

  alienfile_skip_if_missing_prereqs;

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

done_testing;
