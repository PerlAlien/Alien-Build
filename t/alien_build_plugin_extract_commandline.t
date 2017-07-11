use Test2::V0;
use Test::Alien::Build;
use Alien::Build::Plugin::Extract::CommandLine;
use Path::Tiny qw( path );
use Capture::Tiny qw( capture_merged );
use File::Temp qw( tempdir );

subtest 'archive' => sub {

  my $build = alienfile filename => 'corpus/blank/alienfile';
  my $meta = $build->meta;
  
  my $plugin = Alien::Build::Plugin::Extract::CommandLine->new;
  $plugin->init($meta);
  
  subtest 'command probe' => sub {

    foreach my $cmd (qw( gzip bzip2 xz tar unzip ))
    {
      my $method = "${cmd}_cmd";
      my $exe = $plugin->$method;
      $exe = 'undef' unless defined $exe;
      note "$cmd = $exe";
    }

    ok 1;
  };
  
  foreach my $ext (qw( tar tar.Z tar.bz2 tar.gz tar.xz zip ))
  {
    subtest "with extension $ext" => sub {
    
      skip_all "system does not support $ext" unless $plugin->handles($ext);
    
      my $archive = do {
        my $original = path("corpus/dist/foo-1.00.$ext");
        my $new = path(tempdir( CLEANUP => 1))->child("foo-1.00.$ext");
        $original->copy($new);
        $new->stringify;
      };
      
      note "archive = $archive";
      
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
