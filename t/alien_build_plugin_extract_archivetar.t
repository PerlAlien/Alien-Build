use Test2::Bundle::Extended;
use Alien::Build::Plugin::Extract::ArchiveTar;
use lib 't/lib';
use MyTest;
use Path::Tiny qw( path );
use Capture::Tiny qw( capture_merged );
use File::Temp qw( tempdir );

subtest 'archive' => sub {

  foreach my $ext (qw( tar tar.bz2 tar.gz ))
  {
    subtest "with extension $ext" => sub {
    
      my($build, $meta) = build_blank_alien_build;
  
      my $plugin = Alien::Build::Plugin::Extract::ArchiveTar->new;
      $plugin->init($meta);
      eval { $build->load_requires('share') };
    
      skip_all "configuration does not support $ext" if $@;
    
      my $archive = path("corpus/dist/foo-1.00.$ext")->absolute;
      
      my($out, $dir, $error) = capture_merged {
        (eval { $build->extract($archive) }, $@);
      };

      note $out if $out ne '';
      note $error if $error;
      
      $dir = path($dir);

      ok( defined $dir && -d $dir, "directory created"   );
      note "dir = $dir";

      foreach my $name (qw( configure foo.c ))
      {
        my $file = $dir->child($name);
        ok -f $file, "$name exists";
      }
    }
  }
  
};

done_testing;
