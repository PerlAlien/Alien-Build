use 5.008004;
use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use lib 't/lib';
use MyTest::System;
use Alien::Build::Plugin::Probe::CBuilder;
use Capture::Tiny qw( capture_merged );
use Path::Tiny qw( path );

subtest 'basic' => sub {

  my $mock = mock 'ExtUtils::CBuilder';

  my @args_new;
  my @args_compile;
  my @args_link_executable;

  $mock->add('new' => sub {
    shift;
    @args_new = @_;
    bless {}, 'ExtUtils::CBuilder';
  });

  $mock->add('compile' => sub {
    shift;
    @args_compile = @_;
    'mytest.o';
  });

  $mock->add('link_executable' => sub {
    shift;
    @args_link_executable = @_;
    'mytest';
  });

  my $build = alienfile_ok q{
    use alienfile;
    plugin 'Probe::CBuilder' => (
      cflags => '-I/usr/local/include',
      libs   => '-L/usr/local/lib -lfoo',
      options => { foo1 => 1, bar1 => 2 },
    );
  };

  my $gard = system_fake
    './mytest' => sub { 0 },
    'mytest'   => sub { 0 },
  ;

  alien_build_ok;
  alien_install_type_is 'system';

  is( $build->runtime_prop->{cflags}, '-I/usr/local/include ', 'cflags' );
  is( $build->runtime_prop->{libs}, '-L/usr/local/lib -lfoo ', 'libs' );

  is( { @args_new }, { foo1 => 1, bar1 => 2 }, 'options passed to new' );

  is(
    { @args_compile },
    hash {
      field source => T();
      field extra_compiler_flags => '-I/usr/local/include';
      etc;
    },
  );

  is(
    { @args_link_executable },
    hash {
      field objects => array {
        item 'mytest.o';
        end;
      };
      field extra_linker_flags => '-L/usr/local/lib -lfoo';
      etc;
    },
  );

};

subtest 'program' => sub {

  my $mock = mock 'ExtUtils::CBuilder';

  $mock->add('new' => sub {
    bless {}, 'ExtUtils::CBuilder';
  });

  my $source;

  $mock->add('compile' => sub {
    my(undef, %args) = @_;
    $source = path($args{source})->slurp;
    'mytest.o';
  });

  $mock->add('link_executable' => sub {
    'mytest';
  });

  my $build = alienfile q{
    use alienfile;
    plugin 'Probe::CBuilder' => (
      cflags  => '-I/usr/local/include',
      libs    => '-L/usr/local/lib -lfoo',
      program => 'int main(int foo1, char *foo2[]) { return 0; }',
    );
  };

  my $gard = system_fake
    './mytest' => sub { 0 },
    'mytest'   => sub { 0 },
  ;

  note capture_merged { $build->probe; () };

  is( $build->install_type, 'system', 'is system' );
  is($source, 'int main(int foo1, char *foo2[]) { return 0; }', 'compiled with correct source');
};

subtest 'program' => sub {

  my $mock = mock 'ExtUtils::CBuilder';

  $mock->add('new' => sub {
    bless {}, 'ExtUtils::CBuilder';
  });

  $mock->add('compile' => sub {
    my(undef, %args) = @_;
    'mytest.o';
  });

  $mock->add('link_executable' => sub {
    'mytest';
  });

  my $build = alienfile_ok q{
    use alienfile;
    plugin 'Probe::CBuilder' => (
      cflags  => '-I/usr/local/include',
      libs    => '-L/usr/local/lib -lfoo',
      program => 'int main() { printf("version = \'1.2.3\'\n"); return 0; }',
      version => qr/version = '(.*?)'/,
    );

    meta->around_hook(
      probe => sub {
        my($orig, $build) = @_;
        my $install_type = $build->$orig;
        push @{ $build->install_prop->{probe_version_prop} }, $build->hook_prop->{version};
        $install_type;
      }
    );
  };

  my $gard = system_fake
    './mytest' => sub { print "version = '1.2.3'\n"; 0 },
    'mytest'   => sub { print "version = '1.2.3'\n"; 0 },
  ;

  alien_build_ok;
  alien_install_type_is 'system';

  is( $build->runtime_prop->{version}, '1.2.3', 'version matches' );
  is( $build->install_prop->{probe_version_prop}, ['1.2.3'], 'set probe hook prop' );
};

subtest 'fail' => sub {

  my $mock = mock 'ExtUtils::CBuilder';

  $mock->add('new' => sub {
    bless {}, 'ExtUtils::CBuilder';
  });

  subtest 'compile' => sub {

    $mock->add('compile' => sub {
      my(undef, %args) = @_;
      die "error building mytest.o from mytest.c";
    });

    my $build = alienfile_ok q{

      use alienfile;
      plugin 'Probe::CBuilder' => (
        cflags => '-DX=1',
        libs   => '-lfoo',
      );

      probe sub {
        my($build) = @_;
        # some other plugin tries system
        # but doesn't add a gather step
        'system';
      };

    };

    alien_install_type_is 'system';

    my($out, $err) = capture_merged {
      eval { $build->build };
      $@;
    };

    like $err, qr/cbuilder unable to gather;/;

  };

};

done_testing;

package
  ExtUtils::CBuilder;

BEGIN { $INC{'ExtUtils/CBuilder.pm'} = __FILE__ }

