use Test2::V0 -no_srand => 1;
use Test::Alien;
use lib 'corpus/lib';
use Alien::libfoo1;

alien_ok 'Alien::libfoo1';

helper_ok 'foo1';
helper_ok 'foo2', 'something else';

is(
  intercept { helper_ok 'foo1' },
  array {
    event Ok => sub {
      call pass => T();
      call name => 'helper foo1 exists';
    };
    end;
  },
  'default test name',
);

is(
  intercept { helper_ok 'foo2', 'something else' },
  array {
    event Ok => sub {
      call pass => T();
      call name => 'something else';
    };
    end;
  },
  'custom name',
);

is(
  intercept { helper_ok 'foo3' },
  array {
    event Ok => sub {
      call pass => F();
      call name => 'helper foo3 exists';
    };
    event Diag => sub {};
    end;
  },
  'failed test',
);

done_testing;
