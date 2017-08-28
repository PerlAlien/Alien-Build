use Test2::V0 -no_srand => 1;
use Alien::Base::PkgConfig;
use Capture::Tiny qw( capture_merged );

subtest 'basic' => sub {

  my $file = 'corpus/alien_base_modulebuild_pkgconfig/test.pc';
  ok( -e $file, "Test file found" );

  my $pc = Alien::Base::PkgConfig->new($file);
  isa_ok( $pc, 'Alien::Base::PkgConfig' );

  # read tests
  my $pcfiledir = delete $pc->{vars}{pcfiledir};
  ok( -d $pcfiledir, 'pcfiledir is a directory' );
  ok( -e "$pcfiledir/test.pc", 'pcfiledir contains test.pc' );

  is( 
    $pc->{vars}, 
    {
      'INTERNAL_VARIABLE' => '-lotherlib',
      'prefix' => '/home/test/path',
    },
    "read vars"
  );

  is(
    $pc->{keywords},
    {
      'Version' => '1.01',
      'Libs' => '-L/home/test/path/lib -lsomelib ${INTERNAL_VARIABLE} -lm -lm',
      'Cflags' => '-Dfoo=bar -I/home/test/path/deeper/include',
      'Requires' => 'lib1 >= 1.0.0 lib2 >= 1.2.3',
      'Description' => 'My TEST Library',
      'Name' => 'TEST',
    },
    "read keywords"
  );

  is( $pc->{package}, 'test', "understands package name from file path" );

  # vars getter/setter
  is( $pc->var('prefix'), '/home/test/path', "var getter" );
  is( $pc->var(deeper => '/home/test/path/deeper'), '/home/test/path/deeper', "var setter" );

  # abstract vars
  $pc->make_abstract('prefix');

  is( $pc->{vars}{deeper}, '${prefix}/deeper', "abstract vars in terms of each other" );
  is( (split qr/\s+/, $pc->{keywords}{Libs})[0], '-L${prefix}/lib', "abstract simple" );

  $pc->make_abstract('deeper');
  is( $pc->{keywords}{Cflags}, '-Dfoo=bar -I${deeper}/include', "abstract abstract 'nested'" );

  # interpolate vars into keywords
  is( $pc->keyword('Version'), '1.01', "Simple keyword getter" );
  is( (split qr/\s+/, $pc->keyword('Libs'))[0], '-L/home/test/path/lib', "single interpolation keyword" );
  is( $pc->keyword('Cflags'), '-Dfoo=bar -I/home/test/path/deeper/include', "multiple interpolation keyword" );

  # interpolate with overrides
  is( 
    $pc->keyword( 'Cflags', {prefix => '/some/other/path'}), 
    '-Dfoo=bar -I/some/other/path/deeper/include', 
    "multiple interpolation keyword with override"
  );

};

subtest 'version' => sub {
  my $pkg_config = Alien::Base::PkgConfig->pkg_config_command;

  my(undef,$ret) = capture_merged { system( "$pkg_config --version" ); $? };
  if ( $ret ) {
    skip_all "Cannot use pkg-config: $ret";
  }

  my @installed = map { /^(\S+)/ ? $1 : () } `$pkg_config --list-all`;
  skip_all "pkg-config returned no packages" unless @installed;
  my $lib = $installed[0];

  my ($builder_ok, $builder_bad) = map { 
    require Alien::Base::ModuleBuild;
    my($out, $builder) = capture_merged {
      Alien::Base::ModuleBuild->new( 
        module_name => 'My::Test', 
        dist_version => 0.01,
        alien_name => $_,
        share_dir => 't',
      );
    };
    note $out if $out ne '';
    $builder;
  }
  ($lib, 'siughspidghsp');

  subtest 'good' => sub {
  
    my($out, $value) = capture_merged {
      $builder_ok->alien_check_installed_version,
    };
    note $out if $out ne '';
    
    is( $value, T(), 'found installed library' );
    note "lib is $lib";
  
  };
  
  subtest 'bad' => sub {
    my($out, $value) = capture_merged {
      $builder_bad->alien_check_installed_version,
    };
    note $out if $out ne '';
    
    is( $value, F(), "returns false if not found");
    
  };
};

done_testing;

