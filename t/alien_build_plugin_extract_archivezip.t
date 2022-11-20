use 5.008004;
use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Extract::ArchiveZip;
use Path::Tiny qw( path );
use Capture::Tiny qw( capture_merged );
use File::Temp qw( tempdir );

subtest 'available' => sub {

  is(
    Alien::Build::Plugin::Extract::ArchiveZip->available('tar'),
    F(),
    'tar is always false',
  );

  subtest 'with Archive::Zip' => sub {

    local $INC{'Archive/Zip.pm'} = __FILE__;

    is(
      Alien::Build::Plugin::Extract::ArchiveZip->available('zip'),
      T(),
    );

  };

  subtest 'with Archive::Zip' => sub {

    skip_all 'subtest requires Devel::Hide' unless eval { require Devel::Hide };

    note scalar capture_merged { Devel::Hide->import(qw( Archive::Zip )) };

    local %INC;
    delete $INC{'Archive/Zip.pm'};

    is(
      Alien::Build::Plugin::Extract::ArchiveZip->available('zip'),
      F(),
    );

  };

};

subtest 'archive' => sub {

  foreach my $ext (qw( zip ))
  {
    subtest "with extension $ext" => sub {

      my $build = alienfile_ok q{
        use alienfile;
        use Path::Tiny qw( path );
        plugin 'Test::Mock',
          probe    => 'share',
          download => {
            'foo.zip' => path(__FILE__)->parent->parent->child('corpus/dist/foo-1.00.zip')->slurp_raw,
          };
        share {
          plugin 'Extract::ArchiveZip';
        };
      };

      alienfile_skip_if_missing_prereqs;

      my $dir = alien_extract_ok;

      if(defined $dir)
      {
        $dir = path($dir);
        foreach my $name (qw( configure foo.c ))
        {
          my $file = $dir->child($name);
          ok -f $file, "$name exists";
        }
      }
    }
  }

};

done_testing;
