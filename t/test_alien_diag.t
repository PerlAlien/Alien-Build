use 5.008004;
use Test2::V0 -no_srand => 1;
use Test::Alien::Diag;

subtest 'empty' => sub {

  { package Alien::Empty; }

  my $e;

  is
    $e = intercept { alien_diag 'Alien::Empty' },
    array {
      event Diag => sub { call message => ''; };
      event Diag => sub { call message => ''; };
      event Diag => sub { call message => ''; };
      event Diag => sub { call message => 'no diagnostics found for Alien::Empty'; };
      event Diag => sub { call message => ''; };
      event Diag => sub { call message => ''; };
      end;
    }
  ;

  note $_ for map { $_->message } @$e;
};

subtest 'all-the-things' => sub {

  {
    package Alien::Foo;

    use constant cflags       => '-I/foo/include';
    use constant libs         => '-L/foo/lib -lfoo';
    use constant version      => '1.2.3';
    use constant install_type => 'system';

    sub dynamic_libs
    {
      qw(
        /foo/lib/libfoo.so.1.2.3
        /foo/lib/libfoo.so.1
        /foo/lib/libfoo.so
      );
    }

    sub bin_dir
    {
      qw(
        /foo/bin
      );
    }
  }

  my $e;

  is
    $e = intercept { alien_diag 'Alien::Foo' },
    array {
      event Diag => sub { call message => ''; };
      event Diag => sub { call message => ''; };
      event Diag => sub { call message => ''; };
      event Diag => sub { call message => match qr{Alien::Foo->cflags\s+= -I/foo/include}; };
      event Diag => sub { call message => match qr{Alien::Foo->install_type\s+= system}; };
      event Diag => sub { call message => match qr{Alien::Foo->libs\s+= -L/foo/lib -lfoo}; };
      event Diag => sub { call message => match qr{Alien::Foo->version\s+= 1\.2\.3}; };
      event Diag => sub { call message => match qr{Alien::Foo->bin_dir\s+= /foo/bin}; };
      event Diag => sub { call message => match qr{Alien::Foo->dynamic_libs\s+= /foo/lib/libfoo\.so\.1\.2\.3$}; };
      event Diag => sub { call message => match qr{Alien::Foo->dynamic_libs\s+= /foo/lib/libfoo\.so\.1$}; };
      event Diag => sub { call message => match qr{Alien::Foo->dynamic_libs\s+= /foo/lib/libfoo\.so$}; };
      event Diag => sub { call message => ''; };
      event Diag => sub { call message => ''; };
      end;
    }
  ;

  note $_ for map { $_->message } @$e;

};

subtest 'undef' => sub {

  {
    package Alien::Foo1;

    use constant cflags       => undef;
    use constant libs         => undef;
    use constant version      => '4.5.6';
    use constant install_type => 'share';
  }

  my $e;

  is
    $e = intercept { alien_diag 'Alien::Foo1' },
    array {
      event Diag => sub { call message => ''; };
      event Diag => sub { call message => ''; };
      event Diag => sub { call message => ''; };
      event Diag => sub { call message => match qr{Alien::Foo1->cflags\s+= \[undef\]}; };
      event Diag => sub { call message => match qr{Alien::Foo1->install_type\s+= share}; };
      event Diag => sub { call message => match qr{Alien::Foo1->libs\s+= \[undef\]}; };
      event Diag => sub { call message => match qr{Alien::Foo1->version\s+= 4\.5\.6}; };
      event Diag => sub { call message => ''; };
      event Diag => sub { call message => ''; };
      end;
    };

  note $_ for map { $_->message } @$e;

};


subtest 'extra properties' => sub {

  {
    package Alien::Foo2;

    use constant frooble => 'bits';
    sub foo { qw( bar baz ) }
  }

  my $e;

  is
    $e = intercept { alien_diag 'Alien::Foo2', { properties => ['frooble'], list_properties => ['foo'] } },
    array {
      event Diag => sub { call message => ''; };
      event Diag => sub { call message => ''; };
      event Diag => sub { call message => ''; };
      event Diag => sub { call message => match qr{Alien::Foo2->frooble\s+= bits}; };
      event Diag => sub { call message => match qr{Alien::Foo2->foo\s+= bar}; };
      event Diag => sub { call message => match qr{Alien::Foo2->foo\s+= baz}; };
      event Diag => sub { call message => ''; };
      event Diag => sub { call message => ''; };
      end;
    };

  note $_ for map { $_->message } @$e;

  is
    $e = intercept { alien_diag 'Alien::Foo2', { properties => ['frooble'], list_properties => ['foo'], xor => 1 } },
    array {
      event Diag => sub { call message => ''; };
      event Diag => sub { call message => 'warning: unknown option for alien_diag: xor'; };
      event Diag => sub { call message => '(you should check for typos or maybe upgrade to a newer version of Alien::Build)'; };
      event Diag => sub { call message => ''; };
      event Diag => sub { call message => ''; };
      event Diag => sub { call message => match qr{Alien::Foo2->frooble\s+= bits}; };
      event Diag => sub { call message => match qr{Alien::Foo2->foo\s+= bar}; };
      event Diag => sub { call message => match qr{Alien::Foo2->foo\s+= baz}; };
      event Diag => sub { call message => ''; };
      event Diag => sub { call message => ''; };
      end;
    },
    'invalid option';

  note $_ for map { $_->message } @$e;

  is
    $e = intercept { alien_diag 'Alien::Foo2', { properties => ['frooble'], list_properties => ['foo'], abc => 1, def => 2 } },
    array {
      event Diag => sub { call message => ''; };
      event Diag => sub { call message => 'warning: unknown options for alien_diag: abc def'; };
      event Diag => sub { call message => '(you should check for typos or maybe upgrade to a newer version of Alien::Build)'; };
      event Diag => sub { call message => ''; };
      event Diag => sub { call message => ''; };
      event Diag => sub { call message => match qr{Alien::Foo2->frooble\s+= bits}; };
      event Diag => sub { call message => match qr{Alien::Foo2->foo\s+= bar}; };
      event Diag => sub { call message => match qr{Alien::Foo2->foo\s+= baz}; };
      event Diag => sub { call message => ''; };
      event Diag => sub { call message => ''; };
      end;
    },
    'invalid options';

  note $_ for map { $_->message } @$e;

};

subtest 'multiple aliens' => sub {

  my $e;

  is
    $e = intercept { alien_diag 'Alien::Foo', 'Alien::Foo1', 'Alien::Foo2', { properties => ['frooble'], list_properties => ['foo'] } },
    array {
      event Diag => sub { call message => ''; };
      event Diag => sub { call message => ''; };
      event Diag => sub { call message => ''; };
      event Diag => sub { call message => match qr{Alien::Foo->cflags\s+= -I/foo/include}; };
      event Diag => sub { call message => match qr{Alien::Foo->install_type\s+= system}; };
      event Diag => sub { call message => match qr{Alien::Foo->libs\s+= -L/foo/lib -lfoo}; };
      event Diag => sub { call message => match qr{Alien::Foo->version\s+= 1\.2\.3}; };
      event Diag => sub { call message => match qr{Alien::Foo->bin_dir\s+= /foo/bin}; };
      event Diag => sub { call message => match qr{Alien::Foo->dynamic_libs\s+= /foo/lib/libfoo\.so\.1\.2\.3$}; };
      event Diag => sub { call message => match qr{Alien::Foo->dynamic_libs\s+= /foo/lib/libfoo\.so\.1$}; };
      event Diag => sub { call message => match qr{Alien::Foo->dynamic_libs\s+= /foo/lib/libfoo\.so$}; };
      event Diag => sub { call message => ''; };
      event Diag => sub { call message => ''; };
      event Diag => sub { call message => match qr{Alien::Foo1->cflags\s+= \[undef\]}; };
      event Diag => sub { call message => match qr{Alien::Foo1->install_type\s+= share}; };
      event Diag => sub { call message => match qr{Alien::Foo1->libs\s+= \[undef\]}; };
      event Diag => sub { call message => match qr{Alien::Foo1->version\s+= 4\.5\.6}; };
      event Diag => sub { call message => ''; };
      event Diag => sub { call message => ''; };
      event Diag => sub { call message => match qr{Alien::Foo2->frooble\s+= bits}; };
      event Diag => sub { call message => match qr{Alien::Foo2->foo\s+= bar}; };
      event Diag => sub { call message => match qr{Alien::Foo2->foo\s+= baz}; };
      event Diag => sub { call message => ''; };
      event Diag => sub { call message => ''; };
      end;
    };

  note $_ for map { $_->message } @$e;

};

done_testing;
