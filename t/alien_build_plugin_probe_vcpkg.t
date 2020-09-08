use 5.008004;
use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Probe::Vcpkg;
use Path::Tiny;

skip_all 'Test requires Win32::Vcpkg 0.02'
  unless eval { require Win32::Vcpkg; Win32::Vcpkg->VERSION('0.02') };

$ENV{PERL_WIN32_VCPKG_ROOT}  = path('corpus','abpp_vcpkg', 'r1')->absolute->stringify;
$ENV{PERL_WIN32_VCPKG_DEBUG} = 0;
$ENV{VCPKG_DEFAULT_TRIPLET}  = 'x64-windows';

alien_subtest 'non vc' => sub {

  require Alien::Build::Plugin::Core::Setup;
  my $mock = mock 'Alien::Build::Plugin::Core::Setup' => (
    after => [
      _platform => sub {
        my(undef, $hash) = @_;
        $hash->{compiler_type} = 'unix';
      },
    ],
  );

  alienfile_ok q{
    use alienfile;

    plugin 'Probe::Vcpkg' => (
      lib => ['foo'],
    );
  };

  alien_install_type_is 'share';

};

subtest 'vc' => sub {

  my $mock = mock 'Alien::Build::Plugin::Core::Setup' => (
    after => [
      _platform => sub {
        my(undef, $hash) = @_;
        $hash->{compiler_type} = 'microsoft';
        return;
      },
    ],
  );

  alien_subtest 'lib = foo' => sub {

    my $build = alienfile_ok q{
      use alienfile;

      plugin 'Probe::Vcpkg' => (
        lib => ['foo'],
      );
    };

    alien_install_type_is 'system';
    alien_build_ok;

    is(
      $build->runtime_prop,
      hash {
        field version  => 'unknown';
        field cflags   => T();
        field libs     => T();
        field ffi_name => DNE();
        etc;
      },
    );

    note "version = ", $build->runtime_prop->{version};
    note "cflags  = ", $build->runtime_prop->{cflags};
    note "libs    = ", $build->runtime_prop->{libs};
  };

  alien_subtest 'lib = bar' => sub {
    my $build = alienfile_ok q{
      use alienfile;

      plugin 'Probe::Vcpkg' => (
        lib      => ['bar'],
      );
    };

    alien_install_type_is 'share';
  };

  alien_subtest 'ffi_name' => sub {

    local $Alien::Build::Plugin::Probe::Vcpkg::VERSION = '2.14';

    my $build = alienfile_ok q{
      use alienfile;

      plugin 'Probe::Vcpkg' => (
        lib      => ['foo'],
        ffi_name => 'baz',
      );
    };

    alien_install_type_is 'system';
    alien_build_ok;

    is(
      $build->runtime_prop,
      hash {
        field version  => 'unknown';
        field cflags   => T();
        field libs     => T();
        field ffi_name => 'baz';
        etc;
      },
    );

  };

  alien_subtest 'name = libffi' => sub {

    local $ENV{PERL_WIN32_VCPKG_ROOT}  = path('corpus','abpp_vcpkg', 'r2')->absolute->stringify;

    my $build = alienfile_ok q{
      use alienfile;

      plugin 'Probe::Vcpkg' => (
        name => 'libffi',
      );
    };

    alien_install_type_is 'system';
    alien_build_ok;

    is(
      $build->runtime_prop,
      hash {
        field version => '3.3';
        field cflags  => T();
        field libs    => T();
        field ffi_name => DNE();
        etc;
      },
    );

    note "version = ", $build->runtime_prop->{version};
    note "cflags  = ", $build->runtime_prop->{cflags};
    note "libs    = ", $build->runtime_prop->{libs};
  };

  alien_subtest 'libffi' => sub {

    local $ENV{PERL_WIN32_VCPKG_ROOT}  = path('corpus','abpp_vcpkg', 'r2')->absolute->stringify;

    my $build = alienfile_ok q{
      use alienfile;
      plugin 'Probe::Vcpkg' => 'libffi';
    };

    alien_install_type_is 'system';
    alien_build_ok;

    is(
      $build->runtime_prop,
      hash {
        field version => '3.3';
        field cflags  => T();
        field libs    => T();
        field ffi_name => DNE();
        etc;
      },
    );

    note "version = ", $build->runtime_prop->{version};
    note "cflags  = ", $build->runtime_prop->{cflags};
    note "libs    = ", $build->runtime_prop->{libs};
  };
};

done_testing;
