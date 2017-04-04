use Test2::Require::Module 'Test::Exec';
use Test2::Bundle::Extended;
use Test::Exec;
use Config;
use Alien::Base::Wrapper ();

$ENV{ALIEN_BASE_WRAPPER_QUIET} = 1;

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
    [$Config{cc}, qw( -I/foo/include -DBAR=1 one two three )],
    'cc',
  );

  is(
    exec_arrayref {
      local @ARGV = qw( one two three );
      Alien::Base::Wrapper::ld();
    },
    [$Config{ld}, qw( -L/foo/lib one two three -lfoo )],
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
    [$Config{cc}, qw( -I/foo/include -DBAR=2 one two three )],
    'cc',
  );

  is(
    exec_arrayref {
      local @ARGV = qw( one two three );
      Alien::Base::Wrapper::ld();
    },
    [$Config{ld}, qw( -L/foo/lib one two three -lfoo -lbaz )],
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
    [$Config{cc}, qw( -I/foo/include -DBAR=1 one two three )],
    'cc',
  );

  is(
    exec_arrayref {
      local @ARGV = qw( one two three );
      Alien::Base::Wrapper::ld();
    },
    [$Config{ld}, qw( -L/foo/lib one two three -lfoo )],
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

  Alien::Base::Wrapper->import('Alien::Foo5', 'Alien::Bar5');
  
  is(
    exec_arrayref {
      local @ARGV = qw( one two three );
      Alien::Base::Wrapper::cc();
    },
    [$Config{cc}, qw( -I/foo/include -I/bar/include -DFOO5=1 -DBAR5=1 one two three ) ],
    'cc',
  );

  is(
    exec_arrayref {
      local @ARGV = qw( one two three );
      Alien::Base::Wrapper::ld();
    },
    [$Config{cc}, qw( -L/foo/lib -L/foo/lib --ld-foo --ld-bar one two three -lfoo -lbar )],
    'ld',
  );

};

done_testing;
