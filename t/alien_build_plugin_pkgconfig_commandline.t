use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::PkgConfig::CommandLine;
use Path::Tiny qw( path );
use Capture::Tiny qw( capture_merged );

$ENV{PKG_CONFIG_PATH}   = path('corpus/lib/pkgconfig')->absolute->stringify;
$ENV{PKG_CONFIG_LIBDIR} = '';

my $bin_name = Alien::Build::Plugin::PkgConfig::CommandLine->new('foo')->bin_name;
skip_all 'test requires pkgconf or pkg-config' unless $bin_name;

ok $bin_name, 'has bin_name';
note "it be $bin_name";
note "PKG_CONFIG_PATH=$ENV{PKG_CONFIG_PATH}";

my $prefix = '/test';

sub build
{
  my $build = alienfile filename => 'corpus/blank/alienfile';
  my $meta = $build->meta;
  my $plugin = Alien::Build::Plugin::PkgConfig::CommandLine->new(@_);
  $plugin->init($meta);
  ($build, $meta, $plugin);
}

subtest 'available' => sub {

  my %which;

  require File::Which;

  my $mock = Test2::Mock->new(
    class => 'File::Which',
    override => [
      which => sub {
        my($prog) = @_;
        if(defined $prog)
        {
          if($which{$prog})
          {
            note "which: $prog => $which{$prog}";
            return $which{$prog};
          }
          else
          {
            note "which: $prog N/A";
          }
        }
        else
        {
          note "which: undef";
        }
      },
    ],
  );

  subtest 'no command line' => sub {

    %which = ();

    is(
      Alien::Build::Plugin::PkgConfig::CommandLine->available,
      F(),
    );

  };

  subtest 'pkg-config' => sub {

    %which = ( 'pkg-config' => '/usr/bin/pkg-config' );

    is(
      Alien::Build::Plugin::PkgConfig::CommandLine->available,
      T(),
    );

  };

  subtest 'pkgconf' => sub {

    %which = ( 'pkgconf' => '/usr/bin/pkgconf' );

    is(
      Alien::Build::Plugin::PkgConfig::CommandLine->available,
      T(),
    );

  };

  subtest 'PKG_CONFIG' => sub {

    local $ENV{PKG_CONFIG} = 'foo-pkg-config';
    %which = ( 'foo-pkg-config' => '/usr/bin/foo-pkg-config' );

    is(
      Alien::Build::Plugin::PkgConfig::CommandLine->available,
      T(),
    );

  };

};

subtest 'system not available' => sub {

  my($build, $meta, $plugin) = build('bogus');

  my($out, $type) = capture_merged { $build->probe };
  note $out;

  is( $type, 'share' );

};

subtest 'system available, wrong version' => sub {

  my($build, $meta, $plugin) = build(
    pkg_name => 'foo',
    minimum_version => '1.2.4',
  );

  my($out, $type) = capture_merged { $build->probe };
  note $out;

  is( $type, 'share' );

};

subtest 'system available, okay' => sub {

  my($build, $meta, $plugin) = build(
    pkg_name => 'foo',
    minimum_version => '1.2.3',
  );

  my($out, $type) = capture_merged { $build->probe };
  note $out;

  is( $type, 'system' );

  return unless $type eq 'system';

  note capture_merged { $build->build; () };

  if($^O eq 'MSWin32')
  {
    if($build->runtime_prop->{cflags} =~ m/-I(.*)\/include\/foo/
    && $1 ne '/test')
    {
      $prefix = $1;
      ok(-f "$prefix/lib/pkgconfig/foo.pc", "relocation looks okay");
      note "prefix = $prefix\n";
      note "-f $prefix/lib/pkgconfig/foo.pc";
    }
  }

  is(
    $build->runtime_prop,
    hash {
      #field cflags      => match qr/-fPIC/;
      field cflags      => match qr/-I\Q$prefix\E\/include\/foo/;
      field libs        => "-L$prefix/lib -lfoo ";
      field libs_static => "-L$prefix/lib -lfoo -lbar -lbaz ";
      field version     => '1.2.3';
      etc;
    },
  );

  # not supported by pkg-config.
  # may be supported by recent pkgconfig
  # so we do not test it.
  note "cflags_static = @{[ $build->runtime_prop->{cflags_static} ]}";

  is(
    $build->runtime_prop->{alt},
    U(),
  );

};

subtest 'system multiple' => sub {

  subtest 'all found in system' => sub {

    my $build = alienfile_ok q{

      use alienfile;
      plugin 'PkgConfig::CommandLine' => (
        pkg_name => [ 'xor', 'xor-chillout' ],
      );

    };

    alien_install_type_is 'system';

    my $alien = alien_build_ok;

    use Alien::Build::Util qw( _dump );
    note _dump($alien->runtime_prop);

    is(
      $alien->runtime_prop,
      hash {
        field libs          => "-L$prefix/lib -lxor ";
        field libs_static   => "-L$prefix/lib -lxor -lxor1 ";
        field cflags        => "-I$prefix/include/xor ";
        field cflags_static => D();
        field version       => '4.2.1';
        field alt => hash {
          field 'xor' => hash {
            field libs          => "-L$prefix/lib -lxor ";
            field libs_static   => "-L$prefix/lib -lxor -lxor1 ";
            field cflags        => "-I$prefix/include/xor ";
            field cflags_static => D();
            field version       => '4.2.1';
            end;
          };
          field 'xor-chillout' => hash {
            field libs          => "-L$prefix/lib -lxor-chillout ";
            field libs_static   => "-L$prefix/lib -lxor-chillout ";
            field cflags        => "-I$prefix/include/xor ";
            field cflags_static => D();
            field version       => '4.2.2';
          };
          end;
        };
        etc;
      },
    );

  };

};

subtest 'system rewrite' => sub {

  my $build = alienfile_ok q{
    use alienfile;
    use Path::Tiny qw( path );

    meta->prop->{destdir} = 1;

    plugin 'PkgConfig::CommandLine' => (
      pkg_name => [ 'foo-foo' ],
    );

    share {
      download sub { path('file1')->touch };
      extract sub { path('file1')->touch };
      build sub {
        my($build) = @_;
        my $stage = path($ENV{DESTDIR});
        my $prefix = path($build->install_prop->{prefix});

        {
          my $tmp = $prefix->stringify;
          $tmp =~ s!^([a-z]):!/$1!i if $^O eq 'MSWin32';
          $stage = $stage->child($tmp);
        }

        $stage->child('lib/pkgconfig')->mkpath;
        $stage->child('lib/libfoofoo.a')->spew("lib foo-foo as staged\n");

        $stage->child('include')->mkpath;
        $stage->child('include/foofoo.h')->spew("h foo-foo as staged\n");

        $stage->child('lib/pkgconfig/foo-foo.pc')->spew(
          "prefix=$prefix\n",
          map { s/^\s*//; "$_\n" }
          split /\n/,
          q{
            exec_prefix=${prefix}
            libdir=${prefix}/lib
            includedir=${prefix}/include

            Name: foo-foo
            Description: A testing pkg-config file
            Version: 1.2.3
            Libs: -L${libdir} -lfoofoo
            Cflags: -I${includedir}
          },
        );

      };
    };

  };

  alien_install_type_is 'share';

  my $alien = alien_build_ok;

  subtest 'test from stage' => sub {

    my $inc = path($build->runtime_prop->{cflags} =~ /-I(\S*)/);
    my $lib = path($build->runtime_prop->{libs}   =~ /-L(\S*)/);

    ok(-d $inc, "inc dir exists" );
    note "inc = $inc";
    is($inc->child('foofoo.h')->slurp, "h foo-foo as staged\n", 'libfoofoo.a');

    ok(-d $lib, "lib dir exists" );
    note "lib = $lib";
    is($lib->child('libfoofoo.a')->slurp, "lib foo-foo as staged\n", 'libfoofoo.a');

  };

  alien_build_clean;

  subtest 'test from alien' => sub {

    my $inc = path($alien->cflags =~ /-I(\S*)/);
    my $lib = path($alien->libs   =~ /-L(\S*)/);

    ok(-d $inc, "inc dir exists" );
    note "inc = $inc";
    is($inc->child('foofoo.h')->slurp, "h foo-foo as staged\n", 'libfoofoo.a');

    ok(-d $lib, "lib dir exists" );
    note "lib = $lib";
    is($lib->child('libfoofoo.a')->slurp, "lib foo-foo as staged\n", 'libfoofoo.a');

  };

};

done_testing;
