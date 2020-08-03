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
      event Diag => sub { call message => match qr{Alien::Foo->libs\s+= -L/foo/lib -lfoo}; };
      event Diag => sub { call message => match qr{Alien::Foo->version\s+= 1\.2\.3}; };
      event Diag => sub { call message => match qr{Alien::Foo->install_type\s+= system}; };
      event Diag => sub { call message => match qr{Alien::Foo->dynamic_libs\s+= /foo/lib/libfoo\.so\.1\.2\.3$}; };
      event Diag => sub { call message => match qr{Alien::Foo->dynamic_libs\s+= /foo/lib/libfoo\.so\.1$}; };
      event Diag => sub { call message => match qr{Alien::Foo->dynamic_libs\s+= /foo/lib/libfoo\.so$}; };
      event Diag => sub { call message => match qr{Alien::Foo->bin_dir\s+= /foo/bin}; };
      event Diag => sub { call message => ''; };
      event Diag => sub { call message => ''; };
    }
  ;

  note $_ for map { $_->message } @$e;

};

done_testing;
