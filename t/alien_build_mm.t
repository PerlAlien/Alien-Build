use Test2::Bundle::Extended;
use Alien::Build::MM;
use File::chdir;
use File::Temp qw( tempdir );
use Path::Tiny qw( path );

sub alienfile
{
  my($str) = @_;
  my(undef, $filename, $line) = caller;
  $str = '# line '. $line . ' "' . $filename . qq("\n) . $str;
  path('alienfile')->spew($str);
}

@INC = map { ref $_ ? $_ : path($_)->absolute->stringify } @INC;

{ package Config::Foo; $Config::Foo::VERSION = 99; $INC{'Config/Foo.pm'} = __FILE__ }
{ package Config::Bar; $Config::Bar::VERSION = 99; $INC{'Config/Bar.pm'} = __FILE__ }

subtest 'basic' => sub {

  $CWD = tempdir( CLEANUP => 1 );

  alienfile q{
    use alienfile;
    probe sub {
      $ENV{ALIEN_INSTALL_TYPE};
    };
    
    configure {
      requires 'Config::Foo' => '1.234',
      requires 'Config::Bar' => 0,
    };
    
    share {
      requires 'Share::Foo' => '4.567',
    };
    
    sys {
      requires 'Sys::Foo' => '9.99',
    };
  };
  
  subtest 'system' => sub {

    local $ENV{ALIEN_INSTALL_TYPE} = 'system';

    my $mm = Alien::Build::MM->new;
  
    isa_ok $mm, 'Alien::Build::MM';
    isa_ok $mm->build, 'Alien::Build';

    my %args = $mm->mm_args(
      DISTNAME => 'Alien-Foo',
      CONFIGURE_REQUIRES => {
        'YAML' => '1.2',
        'Dancer2' => '3.4',
        'Config::Foo' => '0.09',
        'Config::Bar' => '0.01',
      },
      BUILD_REQUIRES => {
        'Foo::Bar::Baz' => '1.23',
      },
    );

    is(path($mm->build->install_prop->{stage})->basename, 'Alien-Foo', 'stage dir');
    note "stage = @{[ $mm->build->install_prop->{stage} ]}";
  
    is(
      \%args,
      hash {
        field CONFIGURE_REQUIRES => hash {
          field 'YAML' => '1.2';
          field 'Dancer2' => '3.4';
          field 'Config::Foo' => '1.234';
          field 'Config::Bar' => '0.01';
        };
        field BUILD_REQUIRES => hash {
          field 'Foo::Bar::Baz' => '1.23';
          field 'Sys::Foo'      => '9.99';
        };
        etc;
      },
    );
  
    undef $mm;
  
    ok( -d '_alien', "left alien directory" );
    ok( -f '_alien/alien.json', "left alien.json file" );

  };

  subtest 'share' => sub {

    local $ENV{ALIEN_INSTALL_TYPE} = 'share';

    my $mm = Alien::Build::MM->new;
  
    isa_ok $mm, 'Alien::Build::MM';
    isa_ok $mm->build, 'Alien::Build';

    my %args = $mm->mm_args(
      DISTNAME => 'Alien-Foo',
      CONFIGURE_REQUIRES => {
        'YAML' => '1.2',
        'Dancer2' => '3.4',
        'Config::Foo' => '0.09',
        'Config::Bar' => '0.01',
      },
      BUILD_REQUIRES => {
        'Foo::Bar::Baz' => '1.23',
      },
    );

    is(
      \%args,
      hash {
        field CONFIGURE_REQUIRES => hash {
          field 'YAML' => '1.2';
          field 'Dancer2' => '3.4';
          field 'Config::Foo' => '1.234';
          field 'Config::Bar' => '0.01';
        };
        field BUILD_REQUIRES => hash {
          field 'Foo::Bar::Baz' => '1.23';
          field 'Share::Foo'    => '4.567';
        };
        etc;
      },
    );
  
  };
  
};

subtest 'mm_postamble' => sub {

  diag 'TODO';
  ok 1;

};

subtest 'set_prefix' => sub {

  diag 'TODO';
  ok 1;

};

subtest 'build' => sub {

  diag 'TODO';
  ok 1;

};

done_testing;
