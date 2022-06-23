use 5.008004;
use Test2::V0 -no_srand => 1;
use Test::Alien::CanCompile ();
use ExtUtils::CBuilder;
use Capture::Tiny qw( capture_merged );

subtest 'unmocked' => sub {

    my($diag, $ta_cc_skip, $eucb_have_compiler) = capture_merged {
      !!Test::Alien::CanCompile->skip,
      !!ExtUtils::CBuilder->new->have_compiler,
    };
    note $diag;

    is(
      $ta_cc_skip, !$eucb_have_compiler,
      'skip computed by Test::Alien::CanCompile should match ExtUtils::CBuilder#have_compiler'
    );
};

subtest 'skip/import' => sub {

  my $have_compiler;

  my $mock = mock 'ExtUtils::CBuilder' => (
    override => [
      have_compiler => sub { $have_compiler },
    ],
  );

  subtest 'have compiler' => sub {
    $have_compiler = 1;
    is
      [Test::Alien::CanCompile->skip],
      [F()],
      'skip'
    ;
    is
      intercept { Test::Alien::CanCompile->import },
      [],
      'import',
    ;
  };

  subtest 'no compiler' => sub {
    $have_compiler = 0;
    is
      [Test::Alien::CanCompile->skip],
      ['This test requires a compiler.'],
      'skip'
    ;
    is
      intercept { Test::Alien::CanCompile->import },
      array {
        event Plan => sub {
          call directive => 'SKIP';
          call reason => 'This test requires a compiler.';
        };
        end;
      },
      'import',
    ;
  };

};

done_testing;
