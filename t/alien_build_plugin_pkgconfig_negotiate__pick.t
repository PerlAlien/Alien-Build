use Test2::V0 -no_srand => 1;
use Alien::Build::Plugin::PkgConfig::Negotiate;
use Test2::Mock;
use Capture::Tiny qw( capture_merged );
use Config;

subtest 'LibPkgConf' => sub {

  subtest 'installed' => sub {

    local $INC{'PkgConfig/LibPkgConf.pm'} = __FILE__;

    subtest 'new enough' => sub {

      local $PkgConfig::LibPkgConf::VERSION = '0.99';
    
      is(
        Alien::Build::Plugin::PkgConfig::Negotiate->pick,
        'PkgConfig::LibPkgConf',
      );
    };
  
    subtest 'not new enough' => sub {
  
      local $PkgConfig::LibPkgConf::VERSION = '0.01';

      isnt(
        Alien::Build::Plugin::PkgConfig::Negotiate->pick,
        'PkgConfig::LibPkgConf',
      );

    };
  };
  
  subtest 'not installed' => sub {

    skip_all 'subtest requires Devel::Hide' unless eval { require Devel::Hide };
    # side-effect of this test, PkgConfig::LibPkgConf
    # cannot be loaded for the rest of this .t file
    note scalar capture_merged { Devel::Hide->import(qw( PkgConfig::LibPkgConf )) };
  
    isnt(
      Alien::Build::Plugin::PkgConfig::Negotiate->pick,
      'PkgConfig::LibPkgConf',
    );

  };
  
};

my $make_pkgconfig_libpkgconf_unavailable = Test2::Mock->new(
  class => 'Alien::Build::Plugin::PkgConfig::LibPkgConf',
  override => [
    available => sub { 0 },
  ],
);

subtest 'CommandLine' => sub {

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
      Alien::Build::Plugin::PkgConfig::Negotiate->pick,
      'PkgConfig::PP',
    );
  
  };

  subtest 'pkg-config' => sub {
  
    %which = ( 'pkg-config' => '/usr/bin/pkg-config' );
  
    is(
      Alien::Build::Plugin::PkgConfig::Negotiate->pick,
      'PkgConfig::CommandLine',
    );

  };

  subtest 'pkgconf' => sub {
  
    %which = ( 'pkgconf' => '/usr/bin/pkgconf' );
  
    is(
      Alien::Build::Plugin::PkgConfig::Negotiate->pick,
      'PkgConfig::CommandLine',
    );

  };

  subtest 'PKG_CONFIG' => sub {
  
    local $ENV{PKG_CONFIG} = 'foo-pkg-config';
    %which = ( 'foo-pkg-config' => '/usr/bin/foo-pkg-config' );
    
    is(
      Alien::Build::Plugin::PkgConfig::Negotiate->pick,
      'PkgConfig::CommandLine',
    );    
  
  };

};

subtest 'PP' => sub {

  subtest '64 bit solaris' => sub {
  
    # From the old AB::MB days we prefer PkgConfig.pm
    # for 64 bit solaris over the command line pkg-config
    local $^O = 'solaris';
    local %Alien::Build::Plugin::PkgConfig::Negotiate::Config = %Config;
    $Alien::Build::Plugin::PkgConfig::Negotiate::Config{ptrsize} = 8;

    is(
      Alien::Build::Plugin::PkgConfig::Negotiate->pick,
      'PkgConfig::PP',
    );

  };

};

done_testing;

