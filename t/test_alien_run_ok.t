use strict;
use warnings;
use Test2::Bundle::Extended;
use File::Which ();
use File::Spec;
use File::Temp qw( tempdir );
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

sub _prog ($)
{
  my($code) = @_;
  my($package, $filename, $line) = caller;
  my $pl = File::Spec->catfile( tempdir( CLEANUP => 1 ), 'test.pl');
  open my $fh, '>', $pl;
  print $fh qq{# line @{[ $line ]} "@{[ $filename ]}"\n};
  print $fh $code;
  close $fh;
  $pl;
}

subtest 'run with exit 0' => sub {

  plan 16;

  my $run;
  my $prog = _prog q{
    use strict;
    use warnings;
    print "this is some output";
    print STDERR "this is some error";
  };
  
  is(
    intercept { $run = run_ok [ $^X, $prog ], 'run it!' },
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

  $run->note;

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
      event Diag => sub {};
      event Diag => sub {
        call message => '  actual exit value was: 0';
      };
      end;
    },
    "run.exit_is(22)",
  );

  is(
    intercept { $run->exit_isnt(0) },
    array {
      event Ok => sub {
        call pass => F();
        call name => "command exited with value not 0";
      };
      event Diag => sub {};
      event Diag => sub {
        call message => '  actual exit value was: 0';
      };
      end;
    },
    "run.exit_isnt(0)",
  );

  is(
    intercept { $run->exit_isnt(22) },
    array {
      event Ok => sub {
        call pass => T();
        call name => "command exited with value not 22";
      };
      end;
    },
    "run.exit_isnt(22)",
  );

  is(
    intercept { $run->out_like(qr{is some out}) },
    array {
      event Ok => sub {
        call pass => T();
        call name => validator(sub{/^output matches/ });
      };
      end;
    },
    "run.out_like(is some out)",
  );

  is(
    intercept { $run->out_like(qr{bogus}) },
    array {
      event Ok => sub {
        call pass => F();
        call name => validator(sub{/^output matches/ });
      };
      event Diag => sub {};
      event Diag => sub {
        call message => '  out:';
      };
      event Diag => sub {
        call message => '    this is some output';
      };
      event Diag => sub {
        call message => '  does not match:';
      };
      event Diag => sub {
        call message => validator(sub{/^    /});
      };
      end;
    },
    "run.out_like(bogus)",
  );

  is(
    intercept { $run->out_unlike(qr{is some out}) },
    array {
      event Ok => sub {
        call pass => F();
        call name => validator(sub{/^output does not match/ });
      };
      event Diag => sub {};
      event Diag => sub {
        call message => '  out:';
      };
      event Diag => sub {
        call message => '    this is some output';
      };
      event Diag => sub {
        call message => '  matches:';
      };
      event Diag => sub {
        call message => validator(sub{/^    /});
      };
      end;
    },
    "run.out_unlike(is some out)",
  );

  is(
    intercept { $run->out_unlike(qr{bogus}) },
    array {
      event Ok => sub {
        call pass => T();
        call name => validator(sub{/^output does not match/ });
      };
      end;
    },
    "run.out_unlike(bogus)",
  );

  is(
    intercept { $run->err_like(qr{is some err}) },
    array {
      event Ok => sub {
        call pass => T();
        call name => validator(sub{/^standard error matches/ });
      };
      end;
    },
    "run.err_like(is some err)",
  );

  is(
    intercept { $run->err_unlike(qr{bogus}) },
    array {
      event Ok => sub {
        call pass => T();
        call name => validator(sub{/^standard error does not match/ });
      };
      end;
    },
    "run.err_unlike(bogus)",
  );

};

subtest 'run with exit 22' => sub {

  plan 10;

  my $run;
  my $prog = _prog q{
    use strict;
    use warnings;
    print "2x";
    print STDERR "3x";
    exit 22;
  };

  is(
    intercept { $run = run_ok [ $^X, $prog ], 'run it!' },
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
      event Diag => sub {};
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
      event Diag => sub {};
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

  is(
    intercept { $run->exit_isnt(0) },
    array {
      event Ok => sub {
        call pass => T();
        call name => "command exited with value not 0";
      };
      end;
    },
    "run.exit_isnt(0)",
  );

  is(
    intercept { $run->exit_isnt(22) },
    array {
      event Ok => sub {
        call pass => F();
        call name => "command exited with value not 22";
      };
      event Diag => sub {};
      event Diag => sub {
        call message => '  actual exit value was: 22';
      };
      end;
    },
    "run.exit_isnt(22)",
  );

};

subtest 'run with kill 9' => sub {

  skip_all "Test doesn't make sense on Windows" if $^O eq 'MSWin32';

  my $prog = _prog q{
    use strict;
    use warnings;
    kill 9, $$;
  };

  plan 6;

  my $run;

  is(
    intercept { $run = run_ok [ $^X, $prog ], 'run it!' },
    array {
      event Ok => sub {
        call pass => F();
        call name => 'run it!';
      };
      event Diag => sub {};
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
      event Diag => sub {};
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
      event Diag => sub {};
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
      event Diag => sub {};
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
      event Diag => sub {};
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
      event Diag => sub {};
      event Diag => sub {
        call message => validator(sub{/^  failed to execute:/ });
      };
      end;
    },
    "run.success",
  );

};

