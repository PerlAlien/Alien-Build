use Test2::V0 -no_srand => 1;
use Test::Alien::CanPlatypus ();
use ExtUtils::CBuilder;

subtest 'skip/import' => sub {

  subtest 'have platypus' => sub {

    local $INC{'FFI/Platypus.pm'} = __FILE__;
  
    is
      [Test::Alien::CanPlatypus->skip],
      [F()],
      'skip'
    ;
    is
      intercept { Test::Alien::CanPlatypus->import },
      [],
      'import',
    ;
  };

  subtest 'no platypus' => sub {

    $Devel::Hide::VERBOSE =
    $Devel::Hide::VERBOSE = 0;
    skip_all 'test does not work on Perl 5.8' unless $] >= 5.010;
    skip_all 'subtest requires Devel::Hide' unless eval { require Devel::Hide };
    Devel::Hide->import( 'FFI::Platypus' );

    is
      [Test::Alien::CanPlatypus->skip],
      ['This test requires FFI::Platypus.'],
      'skip'
    ;
    is
      intercept { Test::Alien::CanPlatypus->import },
      array {
        event Plan => sub {
          call directive => 'SKIP';
          call reason => 'This test requires FFI::Platypus.';
        };
        end;
      },
      'import',
    ;

  };

};

done_testing;
