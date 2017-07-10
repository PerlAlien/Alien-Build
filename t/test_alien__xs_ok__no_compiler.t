use Test2::V0;
use ExtUtils::CBuilder;

BEGIN {
  no warnings;
  *ExtUtils::CBuilder::have_compiler = sub { 0 };
}

use Test::Alien;

plan 5;

xs_ok '';
xs_ok '', sub {};

is(
  intercept { xs_ok '' },
  array {
    event Skip => sub {
      # doesn't seem to be a way of testing
      # if an event was skipped
      call pass           => T();
      call name           => 'xs';
      call effective_pass => T();
    };
    end;
  },
  'skip works'
);

is(
  intercept { xs_ok '', sub {} },
  array {
    event Skip => sub {
      # doesn't seem to be a way of testing
      # if an event was skipped
      call pass           => T();
      call name           => 'xs';
      call effective_pass => T();
    };
    event Skip => sub {
      # doesn't seem to be a way of testing
      # if an event was skipped
      call pass           => T();
      call name           => 'xs subtest';
      call effective_pass => T();
    };
    end;
  },
  'skip works with cb'
);
