use Test2::Require::Module 'Test::Exec';
use Test2::Bundle::Extended;
use Test::Exec;
use Config;
use Alien::Build::Wrapper ();

$ENV{ALIEN_BUILD_WRAPPER_QUIET} = 1;

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
    use Alien::Build::Wrapper qw( Alien::Foo1 Alien::Bar1 );
  }
  
  ok(
    Foo::Bar1->can('cc'),
    'can cc',
  );

  ok(
    Foo::Bar1->can('ld'),
    'can ld',
  );

};

subtest 'system' => sub {

  Alien::Build::Wrapper::_reset();

  {
    package
      Alien::Foo2;
    
    sub install_type { 'system' }
    sub cflags { '-I/foo/include -DBAR=1' }
    sub cflags_static { 'wrong' }
    sub libs   { '-L/foo/lib -lfoo'   }
    sub libs_static { 'wrong' }
  }
  
  Alien::Build::Wrapper->import('Foo2');
  
  is(
    exec_arrayref {
      local @ARGV = qw( one two three );
      Alien::Build::Wrapper::cc();
    },
    [$Config{cc}, qw( -I/foo/include -DBAR=1 one two three )],
    'cc',
  );

  is(
    exec_arrayref {
      local @ARGV = qw( one two three );
      Alien::Build::Wrapper::ld();
    },
    [$Config{ld}, qw( -L/foo/lib one two three -lfoo )],
    'ld',
  );

};

subtest 'share' => sub {

  Alien::Build::Wrapper::_reset();

  {
    package
      Alien::Foo3;
    
    sub install_type { 'share' }
    sub cflags { '-I/foo/include -DBAR=1' }
    sub cflags_static { '-I/foo/include -DBAR=2' }
    sub libs   { '-L/foo/lib -lfoo'   }
    sub libs_static { '-L/foo/lib -lfoo -lbaz' }
  }
  
  Alien::Build::Wrapper->import('Alien::Foo3');

  is(
    exec_arrayref {
      local @ARGV = qw( one two three );
      Alien::Build::Wrapper::cc();
    },
    [$Config{cc}, qw( -I/foo/include -DBAR=2 one two three )],
    'cc',
  );

  is(
    exec_arrayref {
      local @ARGV = qw( one two three );
      Alien::Build::Wrapper::ld();
    },
    [$Config{ld}, qw( -L/foo/lib one two three -lfoo -lbaz )],
    'ld',
  );

};

subtest 'share sans static' => sub {

  Alien::Build::Wrapper::_reset();

  {
    package
      Alien::Foo4;
    
    sub install_type { 'share' }
    sub cflags { '-I/foo/include -DBAR=1' }
    sub libs   { '-L/foo/lib -lfoo'   }
  }
  
  Alien::Build::Wrapper->import('Alien::Foo4');

  is(
    exec_arrayref {
      local @ARGV = qw( one two three );
      Alien::Build::Wrapper::cc();
    },
    [$Config{cc}, qw( -I/foo/include -DBAR=1 one two three )],
    'cc',
  );

  is(
    exec_arrayref {
      local @ARGV = qw( one two three );
      Alien::Build::Wrapper::ld();
    },
    [$Config{ld}, qw( -L/foo/lib one two three -lfoo )],
    'ld',
  );

};

done_testing;
