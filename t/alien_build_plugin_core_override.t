use 5.008004;
use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Core::Override;

subtest 'basic' => sub {

  subtest 'default' => sub {

    local $ENV{ALIEN_INSTALL_TYPE} = 'default';

    subtest 'system' => sub {

      alienfile_ok q{
        use alienfile;
        probe sub { 'system' };
      };

      alien_install_type_is 'system';

    };

    subtest 'share' => sub {

      alienfile_ok q{
        use alienfile;
        probe sub { 'share' };
      };

      alien_install_type_is 'share';

    };

    subtest 'die' => sub {

      alienfile_ok q{
        use alienfile;
        probe sub { die };
      };

      alien_install_type_is 'share';

    };

  };

  subtest 'share' => sub {

    local $ENV{ALIEN_INSTALL_TYPE} = 'share';

    alienfile_ok q{
      use alienfile;
      probe sub { die "should not get into here!" };
    };

    alien_install_type_is 'share';
  };

  subtest 'system' => sub {

    local $ENV{ALIEN_INSTALL_TYPE} = 'system';

    subtest 'probe okay' => sub {

      alienfile_ok q{
        use alienfile;
        probe sub { 'system' };
      };

      alien_install_type_is 'system';
    };

    subtest 'probe share' => sub {

      my $build = alienfile_ok q{
        use alienfile;
        probe sub { 'share' };
      };

      eval { $build->probe };
      my $error = $@;
      like $error, qr/requested system install not available/;

    };

    subtest 'probe exception' => sub {

      my $build = alienfile_ok q{
        use alienfile;
        probe sub { die 'oops!' };
      };

      eval { $build->probe };
      my $error = $@;
      like $error, qr/oops!/;

    };

  };
};

subtest 'override the override' => sub {

  subtest 'syste, share' => sub {

    local $ENV{ALIEN_INSTALL_TYPE} = 'system';

    alienfile_ok q{
      use alienfile;
      meta->register_hook(override => sub { 'share' });
      probe sub { 'system' };
    };

    alien_install_type_is 'share';

  };

  subtest 'share, system' => sub {

    local $ENV{ALIEN_INSTALL_TYPE} = 'share';

    alienfile_ok q{
      use alienfile;
      meta->register_hook(override => sub { 'system' });
      probe sub { 'system' };
    };

    alien_install_type_is 'system';

  };

};

done_testing;
