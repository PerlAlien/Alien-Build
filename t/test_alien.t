use 5.008004;
use lib 'corpus/lib';
use lib 't/lib';
use Test2::V0 -no_srand => 1;
use Test::Alien;
use Alien::Foo;
use Alien::perlhelp;
use Alien::libfoo1;
use Env qw( @PATH );
use ExtUtils::CBuilder;
use Alien::Build::Util qw( _dump );
use List::Util 1.33 qw( any );
use Config;
use Test2::API 1.302096 ();
use MyTest::HaveCompiler qw( require_compiler );

sub _reset
{
  @Test::Alien::aliens = ();
}

subtest 'alien_ok' => sub {

  _reset();

  local $ENV{PATH} = $ENV{PATH};

  subtest 'as class' => sub {

    local $ENV{PATH} = $ENV{PATH};

    is(
      intercept { alien_ok 'Alien::Foo' },
      array {
        event Ok => sub {
          call pass => T();
          call name => 'Alien::Foo responds to: cflags libs dynamic_libs bin_dir';
        };
        end;
      },
      "alien_ok with class"
    );

    is $PATH[0], '/foo/bar/baz', 'bin_dir added to path';

  };

  subtest 'as object' => sub {

    local $ENV{PATH} = $ENV{PATH};

    my $alien = Alien::Foo->new;

    is(
      intercept { alien_ok $alien },
      array {
        event Ok => sub {
          call pass => T();
          call name => 'Alien::Foo[instance] responds to: cflags libs dynamic_libs bin_dir';
        };
        end;
      },
      "alien_ok with class"
    );

    is $PATH[0], '/foo/bar/baz', 'bin_dir added to path';

  };

  is(
    intercept { alien_ok(Alien::Foo->new) },
    array {
      event Ok => sub {
        call pass => T();
        call name => 'Alien::Foo[instance] responds to: cflags libs dynamic_libs bin_dir';
      };
      end;
    },
    "alien_ok with instance"
  );

  is(
    intercept { alien_ok 'Alien::Bogus' },
    array {
      event Ok => sub {
        call pass => F();
        call name => 'Alien::Bogus responds to: cflags libs dynamic_libs bin_dir';
      };
      event Diag => sub {};
      event Diag => sub {
        call message => "  missing method $_";
      } for qw( cflags libs dynamic_libs bin_dir );
      end;
    },
    "alien_ok with bad class",
  );

  is(
    intercept { alien_ok undef },
    array {
      event Ok => sub {
        call pass => F();
        call name => 'undef responds to: cflags libs dynamic_libs bin_dir';
      };
      event Diag => sub {};
      event Diag => sub {
        call message => '  undefined alien';
      };
      end;
    },
    'alien_ok with undef',
  );

};

subtest 'helper_ok' => sub {

  _reset();

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
};

subtest 'plugin_ok' => sub {

  _reset();

  plugin_ok 'NesAdvantage::HelperTest';
  helper_ok 'nes';
  interpolate_template_is '%{nes}', 'advantage';

};

subtest 'interpolate_template_is' => sub {

  _reset();

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
};

subtest 'ffi_ok' => sub {

  skip_all 'Test requires FFI::Platypus'
    unless eval { require FFI::Platypus; 1 };

  _reset();

  alien_ok synthetic {};

  is(
    intercept { ffi_ok; },
    array {
      event Ok => sub {
        call pass => T();
        call name => 'ffi';
      };
      end;
    },
    'empty ffi'
  );

  ffi_ok {}, 'min version test', with_subtest {
    my($ffi) = @_;
    my $version = $ffi->VERSION;
    $version =~ s/_.*$//;
    cmp_ok $version, '>=', 0.12;
  };

  ffi_ok { ignore_not_found => 1 }, 'ignore not found', with_subtest {
    my($ffi) = @_;
    my $version = $ffi->VERSION;
    $version =~ s/_.*$//;
    cmp_ok $version, '>=', 0.15;
    eval { $ffi->attach( foo => [] => 'void') };
    is $@, '';
    is __PACKAGE__->can('foo'), F();
  };

  ffi_ok { lang => 'Fortran' }, 'lang', with_subtest {
    my($ffi) = @_;
    my $version = $ffi->VERSION;
    $version =~ s/_.*$//;
    cmp_ok $version, '>=', 0.18;
    is $ffi->lang, 'Fortran';
  };

  subtest 'find symbols' => sub {

    subtest 'good symbols' => sub {

      my @symbols;

      my $mock = mock 'FFI::Platypus' => (
        override => [
          find_symbol => sub {
            my(undef, $symbol) = @_;
            push @symbols, $symbol;
            1;
          },
        ],
      );

      is(
        intercept { ffi_ok { symbols => [qw( foo bar baz )] } },
        array {
          event Ok => sub {
            call pass => T();
            call name => 'ffi';
          };
        },
        'test passes',
      );

      is(
        \@symbols,
        [qw( foo bar baz )],
        'tested symbols',
      );

    };

    subtest 'bad symbols' => sub {

      is(
        intercept { ffi_ok { symbols => [qw( bogus1 bogus2 )] } },
        array {
          event Ok => sub {
            call pass => F();
            call name => 'ffi';
          };
          event Diag => sub {};
          event Diag => sub {
            call message => '  bogus1 not found';
          };
          event Diag => sub {
            call message => '  bogus2 not found';
          };
          end;
        },
        'not found error'
      );
    };
  };

  subtest 'acme' => sub {

    skip_all 'Test requires Acme::Alien::DontPanic 0.026'
      unless eval {
         require Acme::Alien::DontPanic;
         Acme::Alien::DontPanic->VERSION('0.026');
       };

    alien_ok 'Acme::Alien::DontPanic';
    ffi_ok { symbols => ['answer'] } , with_subtest {
      my($ffi) = @_;
      is $ffi->function('answer' => [] => 'int')->call(), 42, 'answer is 42';
    };

  };
};

subtest 'xs_ok' => sub {

  require_compiler();
  _reset();

  alien_ok synthetic {};

  is(
    intercept { xs_ok '' },
    array {
      event Ok => sub {
        call pass => F();
        call name => 'xs';
      };
      event Diag => sub {};
      event Diag => sub {
        call message => '  XS does not have a module decleration that we could find';
      };
      end;
    },
    'xs with no module'
  );

  is(
    intercept { xs_ok '', sub { } },
    array {
      event Ok => sub {
        call pass => F();
        call name => 'xs';
      };
      event Diag => sub {};
      event Diag => sub {
        call message => '  XS does not have a module decleration that we could find';
      };
      event Subtest => sub {
        call buffered  => T();
        call subevents => array {
          event Plan => sub {
            call max       => 0;
            call directive => 'SKIP';
            call reason    => 'subtest requires xs success';
          };
          end;
        };
      };
      end;
    },
    'xs fail with subtest'
  );

  # TODO: test that parsexs error should fail

  is(
    intercept { xs_ok "this should cause a compile error\nMODULE = Foo::Bar PACKAGE = Foo::Bar\n" },
    array {
      event Ok => sub {
        call pass => F();
        call name => 'xs';
      };
      event Diag => sub {};
      event Diag => sub {
        call message => '  ExtUtils::CBuilder->compile failed';
      };
      etc;
    },
    'xs with C compile error'
  );

  # TODO: test that link error should fail

  subtest 'good' => sub {
    my $xs = <<'EOF';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

int baz(const char *class)
{
  return 42;
}

MODULE = TA_MODULE PACKAGE = TA_MODULE

int baz(class);
    const char *class;
EOF

    xs_ok { xs => $xs, verbose => 1 }, with_subtest {
      my($module) = @_;
      is $module->baz(), 42, "call $module->baz()";
    };

    $xs =~ s{\bTA_MODULE\b}{Foo::Bar}g;
    xs_ok $xs, 'xs without parameterized name', with_subtest {
      my($module) = @_;
      is $module, 'Foo::Bar';
      is $module->baz(), 42, "call $module->baz()";
    };

  };

  subtest 'with xs_load' => sub {

    _reset();

    my $xs = <<'EOF';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = TA_MODULE PACKAGE = TA_MODULE

int
get_foo_one(klass)
    const char *klass
  CODE:
    RETVAL = FOO_ONE;
  OUTPUT:
    RETVAL

int
get_foo_two(klass)
    const char *klass
  CODE:
    RETVAL = FOO_TWO;
  OUTPUT:
    RETVAL
EOF

    my @aliens = (
      synthetic({ cflags => '-DFOO_ONE=42' }),
      synthetic({ cflags => '-DFOO_TWO=47' }),
    );

    alien_ok $aliens[0];
    alien_ok $aliens[1];

    my @xs_load_args;

      my $mock = mock 'Test::Alien::Synthetic' => (
      add => [
        xs_load => sub {
          my($alien, $module, $version, @rest) = @_;
          @xs_load_args = @_;
          require XSLoader;
          XSLoader::load($module, $version);
        },
      ],
    );

    xs_ok { xs => $xs, verbose => 1 }, with_subtest {
      my($mod) = @_;
      is($mod->get_foo_one, 42, 'get_foo_one');
      is($mod->get_foo_two, 47, 'get_foo_two');
    };

    is(
      \@xs_load_args,
      array {
        item object {
          call 'cflags' => '-DFOO_ONE=42';
        };
        item match(qr{^Test::Alien::XS::Mod});
        item '0.01';
        item object {
          call 'cflags' => '-DFOO_TWO=47';
        };
        end;
      },
      'called xs_load with correct args',
    );

  };

  subtest 'acme' => sub {

    skip_all 'Test requires Acme::Alien::DontPanic 0.026'
      unless eval {
         require Acme::Alien::DontPanic;
         Acme::Alien::DontPanic->VERSION('0.026');
       };

    reset();

    my $xs = <<'EOF';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <libdontpanic.h>

MODULE = Acme PACKAGE = Acme

int answer();
EOF

    alien_ok 'Acme::Alien::DontPanic';
    xs_ok $xs, with_subtest {
      is Acme::answer(), 42, 'answer is 42';
    };

  };
};

subtest 'xs_ok without no compiler' => sub {

  my $mock = mock 'ExtUtils::CBuilder' => (
    'class' => 'ExtUtils::CBuilder',
    override => [
      have_compiler => sub {
        0;
      },
    ],
  );

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

};

subtest 'overrides no overrides' => sub {

  _reset();

  alien_ok synthetic { cflags => '-DD1=22' };

  my $xs = <<'EOF';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

int
answer(const char *klass)
{
#ifdef D1
#ifdef D2
  return D1+D2;
#else
  return D1;
#endif
#else
#ifdef D2
  return D2;
#else
  return 0;
#endif
#endif
}

MODULE = TA_MODULE PACKAGE = TA_MODULE

int answer(klass);
    const char *klass;
EOF

  xs_ok { xs => $xs, cbuilder_compile => { extra_compiler_flags => '-DD2=20' }, verbose => 1 }, 'extra compiler flags as string', with_subtest {
    my($mod) = @_;
    is($mod->answer, 42);
  };

  xs_ok { xs => $xs, cbuilder_compile => { extra_compiler_flags => ['-DD2=20'] }, verbose => 1 }, 'extra compiler flags as array ref', with_subtest {
    my($mod) = @_;
    is($mod->answer, 42);
  };

  my $cbuilder_config;

  no warnings 'once';
  local *ExtUtils::CBuilder::new = do {
    my $orig = ExtUtils::CBuilder->can('new');
    sub {
      my $class = shift;
      my %args = @_;
      $cbuilder_config = $args{config};
      $class->$orig(@_);
    };
  };

  xs_ok { xs => $xs, cbuilder_config => { foo => 'bar' } };

  is
    $cbuilder_config,
    hash {
      field 'foo' => 'bar';
      etc;
    }
  ;

};

subtest 'with_subtest SEGV' => sub {

  # it may be possible to catch a segmentation fault,
  # but not with signal handlers apparently.  See:
  # https://feepingcreature.github.io/handling.html
  skip_all 'Catching SEGV not currently supported on Windows' if $^O eq 'MSWin32';

  skip_all 'Test requires platforms with SEGV signal' if ! any { $_ eq 'SEGV' } split /\s+/, $Config{sig_name};

  our $kill_line;

  my $st = with_subtest {
    note 'one';
    kill 'SEGV', $$; BEGIN { $kill_line = __LINE__ };
    note 'two';
  };

  my $e;

  is(
    $e = intercept {
      $st->();
    },
    array {
      event Note => sub {
        call message => 'one';
      };
      event Bail => sub {
        call reason => 'Segmentation fault';
        call facet_data => hash {
          field trace => hash {
            field frame => array {
              item 'main';
              item __FILE__;
              item $kill_line;
              etc;
            };
            etc;
          };
          etc;
        };
        etc;
      };
      end;
    },
  ) or diag _dump($e);

};

subtest 'diagnostic when calling tools without alien_ok' => sub {

  _reset();
  require_compiler;

  my $xs = <<'EOF';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = TA_MODULE PACKAGE = TA_MODULE

int answer();
  CODE:
    RETVAL = 1;
EOF

  is
    intercept { xs_ok { xs => $xs } },
    array {
      event Ok => sub {
        call pass => T();
        call name => 'xs';
      };
      event Diag => sub {
        call message => 'xs_ok called without any aliens, you may want to call alien_ok';
      };
      end;
    },
    'xs_ok displays dignostic sans alien_ok',
  ;

  is
    intercept { run_ok [$^X, -e => '1'] },
    array {
      event Ok => sub {
        call pass => T();
        call name => match qr/^run/;
      };
      event Note => sub {};
      event Diag => sub {
        call message => 'run_ok called without any aliens, you may want to call alien_ok';
      };
      end;
    },
    'run_ok displays diagnostic sans alien_ok',
  ;

  is
    intercept { run_ok "$^X -e 1" },
    array {
      event Ok => sub {
        call pass => T();
        call name => match qr/^run/;
      };
      event Note => sub {};
      event Diag => sub {
        call message => 'run_ok called without any aliens, you may want to call alien_ok';
      };
      end;
    },
    'run_ok displays diagnostic sans alien_ok',
  ;

  if(eval { require FFI::Platypus; 1 })
  {
    is
      intercept { ffi_ok; },
      array {
        event Ok => sub {
          call pass => T();
          call name => 'ffi';
        };
        event Diag => sub {
          call message => 'ffi_ok called without any aliens, you may want to call alien_ok';
        };
        end;
      },
      'ffi_ok displays diagnostic sans alien_ok',
    ;
  }

  is
    intercept { helper_ok 'foo' },
    array {
      event Ok => sub {
        call pass => F();
        call name => 'helper foo exists';
      };
      event Diag => sub {};
      event Diag => sub {
        call message => 'helper_ok called without any aliens, you may want to call alien_ok';
      };
      end;
    },
    'helper_ok displays diagnostic sans alien_ok',
  ;

  is
    intercept { interpolate_template_is "foo", "foo" },
    array {
      event Ok => sub {
        call pass => T();
        call name => 'template matches';
      };
      event Diag => sub {
        call message => 'interpolate_template_is called without any aliens, you may want to call alien_ok';
      };
      end;
    },
    'interpolate_template_is called without any aliens, you may want to call alien_ok',
  ;

};

subtest 'interpolate_run_ok' => sub {

  _reset();

  alien_ok 'Alien::perlhelp';

  is
    intercept { interpolate_run_ok '%{bogus}' },
    array {
      event Ok => sub {
        call pass => F();
        call name => 'run %{bogus}';
      };
      event Diag => sub {};
      event Diag => sub {
        call message => 'error in evaluation:';
      };
      event Diag => sub {
        call message => match qr/^  no helper defined for bogus at/;
      };
      end;
    },
    'run with bogus macro should fail',
  ;

  interpolate_run_ok ['%{perlhelp}', -e => '1'];
  interpolate_run_ok '%{perlhelp} -e 1';

};

done_testing;
