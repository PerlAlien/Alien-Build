use 5.008004;
use Test2::V0 -no_srand => 1;
use Config;
use Alien::Base::Wrapper ();
use Alien::Build::Util qw( _dump );
use Text::ParseWords qw( shellwords );

$ENV{ALIEN_BASE_WRAPPER_QUIET} = 1;

sub exec_arrayref (&)
{
  my($code) = @_;

  my @answer;

  my $mock = mock 'Alien::Base::Wrapper' => (
    override => [
      _myexec => sub {
        @answer = @_;
      },
    ],
  );

  $code->();

  \@answer;
}

subtest 'export' => sub {

  {
    package
      Alien::Foo1;

    sub install_type { 'share' }
    sub cflags {}
    sub libs {}

    package
      Alien::Bar1;

    sub install_type { 'share' }
    sub cflags {}
    sub libs {}

    package
      Foo::Bar1;
    use Alien::Base::Wrapper qw( Alien::Foo1 Alien::Bar1 );

    package
      Foo::Bar2;
    use Alien::Base::Wrapper qw( WriteMakefile );
  }

  ok(
    Foo::Bar1->can('cc'),
    'can cc',
  );

  ok(
    Foo::Bar1->can('ld'),
    'can ld',
  );

  ok(
    Foo::Bar2->can('WriteMakefile'),
    'can WriteMakefile',
  );

};

subtest 'system' => sub {

  Alien::Base::Wrapper::_reset();

  {
    package
      Alien::Foo2;

    sub install_type { 'system' }
    sub cflags { '-I/foo/include -DBAR=1' }
    sub cflags_static { 'wrong' }
    sub libs   { '-L/foo/lib -lfoo'   }
    sub libs_static { 'wrong' }
  }

  Alien::Base::Wrapper->import('Foo2');

  is(
    exec_arrayref {
      local @ARGV = qw( one two three );
      Alien::Base::Wrapper::cc();
    },
    [shellwords($Config{cc}), qw( -I/foo/include -DBAR=1 one two three )],
    'cc',
  );

  is(
    exec_arrayref {
      local @ARGV = qw( one two three );
      Alien::Base::Wrapper::ld();
    },
    [shellwords($Config{ld}), qw( -L/foo/lib one two three -lfoo )],
    'ld',
  );

};

subtest 'share' => sub {

  Alien::Base::Wrapper::_reset();

  {
    package
      Alien::Foo3;

    sub install_type { 'share' }
    sub cflags { '-I/foo/include -DBAR=1' }
    sub cflags_static { '-I/foo/include -DBAR=2' }
    sub libs   { '-L/foo/lib -lfoo'   }
    sub libs_static { '-L/foo/lib -lfoo -lbaz' }
  }

  Alien::Base::Wrapper->import('Alien::Foo3');

  is(
    exec_arrayref {
      local @ARGV = qw( one two three );
      Alien::Base::Wrapper::cc();
    },
    [shellwords($Config{cc}), qw( -I/foo/include -DBAR=2 one two three )],
    'cc',
  );

  is(
    exec_arrayref {
      local @ARGV = qw( one two three );
      Alien::Base::Wrapper::ld();
    },
    [shellwords($Config{ld}), qw( -L/foo/lib one two three -lfoo -lbaz )],
    'ld',
  );

};

subtest 'share sans static' => sub {

  Alien::Base::Wrapper::_reset();

  {
    package
      Alien::Foo4;

    sub install_type { 'share' }
    sub cflags { '-I/foo/include -DBAR=1' }
    sub libs   { '-L/foo/lib -lfoo'   }
  }

  Alien::Base::Wrapper->import('Alien::Foo4');

  is(
    exec_arrayref {
      local @ARGV = qw( one two three );
      Alien::Base::Wrapper::cc();
    },
    [shellwords($Config{cc}), qw( -I/foo/include -DBAR=1 one two three )],
    'cc',
  );

  is(
    exec_arrayref {
      local @ARGV = qw( one two three );
      Alien::Base::Wrapper::ld();
    },
    [shellwords($Config{ld}), qw( -L/foo/lib one two three -lfoo )],
    'ld',
  );

};

subtest 'combine aliens' => sub {

  Alien::Base::Wrapper::_reset();

  {
    package
      Alien::Foo5;

    sub install_type { 'system' }
    sub cflags { '-I/foo/include -DFOO5=1' }
    sub libs   { '-L/foo/lib --ld-foo -lfoo' }

    package
      Alien::Bar5;

    sub install_type { 'share' }
    sub cflags { '-I/bar/include -DBAR5=1' }
    sub libs   { '-L/foo/lib --ld-bar -lbar' }
  }

  Alien::Base::Wrapper->import('Alien::Foo5', 'Alien::Bar5=1.23');

  is(
    exec_arrayref {
      local @ARGV = qw( one two three );
      Alien::Base::Wrapper::cc();
    },
    [shellwords($Config{cc}), qw( -I/foo/include -I/bar/include -DFOO5=1 -DBAR5=1 one two three ) ],
    'cc',
  );

  is(
    exec_arrayref {
      local @ARGV = qw( one two three );
      Alien::Base::Wrapper::ld();
    },
    [shellwords($Config{ld}), qw( -L/foo/lib -L/foo/lib --ld-foo --ld-bar one two three -lfoo -lbar )],
    'ld',
  );

  subtest 'mm_args' => sub {

    my %mm_args = Alien::Base::Wrapper->mm_args;

    note _dump(\%mm_args);

    is(
      \%mm_args,
      hash {
        field DEFINE    => '-DFOO5=1 -DBAR5=1';
        field INC       => '-I/foo/include -I/bar/include';
        field LIBS      => [ match(qr{-lfoo -lbar$}) ];
        field LDDLFLAGS => T();
        field LDFLAGS   => T();
      },
    );

  };

  subtest 'mm_args2' => sub {

    my %mm_args = Alien::Base::Wrapper->mm_args2( foo => 'bar', INC => '-I/baz/include' );

    note _dump(\%mm_args);

    is(
      \%mm_args,
      hash {
        field DEFINE    => '-DFOO5=1 -DBAR5=1';
        field INC       => '-I/foo/include -I/bar/include -I/baz/include';
        field LIBS      => [ match(qr{-lfoo -lbar$}) ];
        field LDDLFLAGS => T();
        field LDFLAGS   => T();
        field foo       => 'bar';
        field CONFIGURE_REQUIRES => hash {
          field 'ExtUtils::MakeMaker'  => '6.52';
          field 'Alien::Base::Wrapper' => '1.97';
          field 'Alien::Bar5'          => '1.23';
          field 'Alien::Foo5'          => '0';
        };
      },
    );

  };

  subtest 'WriteMakefile' => sub {

    local $@ = '';
    eval { require ExtUtils::MakeMaker; ExtUtils::MakeMaker->VERSION('6.52') };
    skip_all "test requires EUMM 6.52: $@" if $@;

    my %mm_args;

    my $mock = mock 'ExtUtils::MakeMaker' => (
      override => [
        WriteMakefile => sub {
          %mm_args = @_;
          42;
        },
      ],
    );

    $@ = '';
    my $ret = eval {
      Alien::Base::Wrapper::WriteMakefile(
        alien_requires => [ 'Alien::Foo5', 'Alien::Bar5=1.23' ],
        foo => 'bar',
        INC => '-I/baz/include',
      );
    };

    is "$@", '';
    is $ret, 42;
    is(
      \%mm_args,
      hash {
        field DEFINE    => '-DFOO5=1 -DBAR5=1';
        field INC       => '-I/foo/include -I/bar/include -I/baz/include';
        field LIBS      => [ match(qr{-lfoo -lbar$}) ];
        field LDDLFLAGS => T();
        field LDFLAGS   => T();
        field foo       => 'bar';
        field CONFIGURE_REQUIRES => hash {
          field 'ExtUtils::MakeMaker'  => '6.52';
          field 'Alien::Base::Wrapper' => '1.97';
          field 'Alien::Bar5'          => '1.23';
          field 'Alien::Foo5'          => '0';
        };
      },
    );

    $@ = '';
    $ret = Alien::Base::Wrapper::WriteMakefile(
      alien_requires => { 'Alien::Foo5' => 0, 'Alien::Bar5' => '1.23' },
      foo => 'bar',
      INC => '-I/baz/include',
    );

    is "$@", '';
    is $ret, 42;
    is(
      \%mm_args,
      hash {
        field DEFINE    => '-DBAR5=1 -DFOO5=1';
        field INC       => '-I/bar/include -I/foo/include -I/baz/include';
        field LIBS      => [ match(qr{-lbar -lfoo$}) ];
        field LDDLFLAGS => T();
        field LDFLAGS   => T();
        field foo       => 'bar';
        field CONFIGURE_REQUIRES => hash {
          field 'ExtUtils::MakeMaker'  => '6.52';
          field 'Alien::Base::Wrapper' => '1.97';
          field 'Alien::Bar5'          => '1.23';
          field 'Alien::Foo5'          => '0';
        };
      },
    );

  };

  subtest 'mb_args' => sub {

    my %mb_args = Alien::Base::Wrapper->mb_args;

    note _dump(\%mb_args);

    is(
      \%mb_args,
      hash {
        field extra_compiler_flags => '-I/foo/include -I/bar/include -DFOO5=1 -DBAR5=1';
        field extra_linker_flags   => '-lfoo -lbar';
        field config => hash {
          field lddlflags => T();
          field ldflags   => T();
        };
      },
    );


  };

};

subtest 'oo interface' => sub {

  subtest '_export' => sub {

    my $abw = Alien::Base::Wrapper->new;
    isa_ok $abw, 'Alien::Base::Wrapper';
    is $abw->_export, T();

    $abw = Alien::Base::Wrapper->new('!export');
    isa_ok $abw, 'Alien::Base::Wrapper';
    is $abw->_export, F();

  };
};

done_testing;
