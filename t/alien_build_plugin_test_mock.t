use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Test::Mock;

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

done_testing;
