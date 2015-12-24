use strict;
use warnings;
use Test::Stream qw( -V1 -Tester Subtest );
use File::Which ();
BEGIN {
  our $which = \&File::Which::which;
  no warnings;
  *File::Which::which = sub {
    $which->(@_);
  };
};
use Test::Alien;

plan 3;

subtest 'run with exit 0' => sub {

  plan 5;

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
    "run_ok with normal exit",
  );

  is $run->out, 'this is some output', 'output';
  is $run->err, 'this is some error', 'error';
  is $run->exit, 0, 'exit';
  is $run->signal, 0, 'signal';

};

subtest 'run with exit 22' => sub {

  plan 5;

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
    "run_ok with normal exit",
  );

  is $run->out, '2x', 'output';
  is $run->err, '3x', 'error';
  is $run->exit, 22, 'exit';
  is $run->signal, 0, 'signal';

};

subtest 'run with kill 9' => sub {

  my $prog = '# line '. __LINE__ . ' "' . __FILE__ . qq("\n) . q{
    use strict;
    use warnings;
    kill 9, $$;
  };

  plan 5;

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
    "run_ok with not found",
  );

  is $run->out, '', 'output';
  is $run->err, '', 'error';
  is $run->exit, 0, 'exit';
  is $run->signal, 9, 'signal';

};

