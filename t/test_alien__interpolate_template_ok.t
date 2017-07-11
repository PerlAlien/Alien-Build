use Test2::V0;
use Test::Alien;
use lib 'corpus/lib';
use Alien::libfoo1;

alien_ok 'Alien::libfoo1';

interpolate_template_is '%{foo1}', 'bar3';
interpolate_template_is '%{foo2}', qr{az7};

is(
  intercept { interpolate_template_is '%{foo1}', 'bar3' },
  array {
    event Ok => sub {
      call pass => T();
      call name => 'template matches';
    };
    end;
  },
  'pass with default name',
);

is(
  intercept { interpolate_template_is '%{foo1}', 'bar3', 'something else' },
  array {
    event Ok => sub {
      call pass => T();
      call name => 'something else';
    };
    end;
  },
  'pass with custom name',
);

is(
  intercept { interpolate_template_is '%{foo1}', 'bar4' },
  array {
    event Ok => sub {
      call pass => F();
      call name => 'template matches';
    };
    event Diag => sub {};
    event Diag => sub {
      call message => 'value \'bar3\' does not equal \'bar4\'';
    };
    end;
  },
  'fail with string match',
);

is(
  intercept { interpolate_template_is '%{foo1}', qr{xx} },
  array {
    event Ok => sub {
      call pass => F();
      call name => 'template matches';
    };
    event Diag => sub {};
    event Diag => sub {
      call message => match(qr{^value 'bar3' does not match });
    };
    end;
  },
  'fail with string match',
);

is(
  intercept { interpolate_template_is '%{bogus}', 'bar4' },
  array {
    event Ok => sub {
      call pass => F();
      call name => 'template matches';
    };
    event Diag => sub {};
    event Diag => sub {
      call message => 'error in evaluation:';
    };
    event Diag => sub {
      call message => match(qr/^  /);
    };
    end;
  },
  'bogus helper',
);

done_testing;
