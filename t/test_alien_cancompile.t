use Test2::V0 -no_srand => 1;
use Test::Alien::CanCompile ();
use ExtUtils::CBuilder;

subtest 'unmocked' => sub {
    is(
      !!Test::Alien::CanCompile->skip,
      !ExtUtils::CBuilder->new->have_compiler,
      'skip'
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
