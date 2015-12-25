use strict;
use warnings;
use Test::Stream qw( -V1 -Tester Subtest );
use File::Which ();
our $which;
our $system;
BEGIN {
  $which = \&File::Which::which;
  no warnings;
  *File::Which::which = sub {
    $which->(@_);
  };
  
  $system = sub {
    CORE::system(@_);
  };
  *CORE::GLOBAL::system = sub { $system->(@_) };
};
use Test::Alien;

plan 5;

subtest 'run with exit 0' => sub {

  plan 8;

  my $run;
  my $prog = '# line '. __LINE__ . ' "' . __FILE__ . qq("\n) . q{
    use strict;
    use warnings;
    print "this is some output";
    print STDERR "this is some error";
  };

  is(
    intercept { $run = run_ok [ $^X, -e => $prog ], 'run it!' },
    array {
      event Ok => sub {
        call pass => T();
        call name => 'run it!';
      };
      event Note => sub {
        call message => "  using $^X";
      };
      end;
    },
    "run_ok",
  );

  is $run->out, 'this is some output', 'output';
  is $run->err, 'this is some error', 'error';
  is $run->exit, 0, 'exit';
  is $run->signal, 0, 'signal';

  is(
    intercept { $run->success },
    array {
      event Ok => sub {
        call pass => T();
        call name => "command succeeded"
      };
      end;
    },
    "run.success",
  );

  is(
    intercept { $run->exit_is(0) },
    array {
      event Ok => sub {
        call pass => T();
        call name => "command exited with value 0";
      };
      end;
    },
    "run.exit_is(0)",
  );

  is(
    intercept { $run->exit_is(22) },
    array {
      event Ok => sub {
        call pass => F();
        call name => "command exited with value 22";
      };
      event Diag => sub {
        call message => '  actual exit value was: 0';
      };
      end;
    },
    "run.exit_is(22)",
  );

};

subtest 'run with exit 22' => sub {

  plan 8;

  my $run;
  my $prog = '# line '. __LINE__ . ' "' . __FILE__ . qq("\n) . q{
    use strict;
    use warnings;
    print "2x";
    print STDERR "3x";
    exit 22;
  };

  is(
    intercept { $run = run_ok [ $^X, -e => $prog ], 'run it!' },
    array {
      event Ok => sub {
        call pass => T();
        call name => 'run it!';
      };
      event Note => sub {
        call message => "  using $^X";
      };
      end;
    },
    "run_ok",
  );

  is $run->out, '2x', 'output';
  is $run->err, '3x', 'error';
  is $run->exit, 22, 'exit';
  is $run->signal, 0, 'signal';

  is(
    intercept { $run->success },
    array {
      event Ok => sub {
        call pass => F();
        call name => "command succeeded"
      };
      event Diag => sub {
        call message => '  command exited with 22';
      };
      end;
    },
    "run.success",
  );

  is(
    intercept { $run->exit_is(0) },
    array {
      event Ok => sub {
        call pass => F();
        call name => "command exited with value 0";
      };
      event Diag => sub {
        call message => '  actual exit value was: 22';
      };
      end;
    },
    "run.exit_is(0)",
  );

  is(
    intercept { $run->exit_is(22) },
    array {
      event Ok => sub {
        call pass => T();
        call name => "command exited with value 22";
      };
      end;
    },
    "run.exit_is(22)",
  );

};

subtest 'run with kill 9' => sub {

  my $prog = '# line '. __LINE__ . ' "' . __FILE__ . qq("\n) . q{
    use strict;
    use warnings;
    kill 9, $$;
  };

  plan 6;

  my $run;

  is(
    intercept { $run = run_ok [ $^X, -e => $prog ], 'run it!' },
    array {
      event Ok => sub {
        call pass => F();
        call name => 'run it!';
      };
      event Diag => sub {
        call message => "  using $^X";
      };
      event Diag => sub {
        call message => "  killed with signal: 9";
      };
      end;
    },
    "run_ok",
  );

  is $run->out, '', 'output';
  is $run->err, '', 'error';
  is $run->exit, 0, 'exit';
  is $run->signal, 9, 'signal';

  is(
    intercept { $run->success },
    array {
      event Ok => sub {
        call pass => F();
        call name => "command succeeded"
      };
      event Diag => sub {
        call message => '  command killed with 9';
      };
      end;
    },
    "run.success",
  );

};

subtest 'run with not found' => sub {

  local $which = sub { undef() };

  plan 6;

  my $run;

  is(
    intercept { $run = run_ok [ qw( foo bar baz ) ] },
    array {
      event Ok => sub {
        call pass => F();
        call name => 'run foo bar baz';
      };
      event Diag => sub {
        call message => "  command not found";
      };
      end;
    },
    "run_ok",
  );

  is $run->out, '', 'output';
  is $run->err, '', 'error';
  is $run->exit, 0, 'exit';
  is $run->signal, 0, 'signal';

  is(
    intercept { $run->success },
    array {
      event Ok => sub {
        call pass => F();
        call name => "command succeeded"
      };
      event Diag => sub {
        call message => '  command not found';
      };
      end;
    },
    "run.success",
  );

};

subtest 'run -1' => sub {

  local $which = sub { '/baz/bar/foo' };
  local $system = sub { $? = -1; $! = 2; };

  plan 6;

  my $run;

  is(
    intercept { $run = run_ok [ qw( foo bar baz ) ] },
    array {
      event Ok => sub {
        call pass => F();
        call name => 'run foo bar baz';
      };
      event Diag => sub {
        call message => "  using /baz/bar/foo";
      };
      event Diag => sub {
        call message => validator(sub{/^  failed to execute:/ });
      };
      end;
    },
    "run_ok",
  );

  is $run->out, '', 'output';
  is $run->err, '', 'error';
  is $run->exit, 0, 'exit';
  is $run->signal, 0, 'signal';

  is(
    intercept { $run->success },
    array {
      event Ok => sub {
        call pass => F();
        call name => "command succeeded"
      };
      event Diag => sub {
        call message => validator(sub{/^  failed to execute:/ });
      };
      end;
    },
    "run.success",
  );

};

