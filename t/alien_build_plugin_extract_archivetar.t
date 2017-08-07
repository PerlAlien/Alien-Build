use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Extract::ArchiveTar;
use Path::Tiny qw( path );
use Capture::Tiny qw( capture_merged );
use File::Temp qw( tempdir );
use Alien::Build::Util qw( _dump );

subtest 'archive' => sub {

  foreach my $ext (qw( tar tar.bz2 tar.gz ))
  {
    subtest "with extension $ext" => sub {

      my $build = alienfile filename => 'corpus/blank/alienfile';
      my $meta = $build->meta;

      my $plugin = Alien::Build::Plugin::Extract::ArchiveTar->new;
      $plugin->init($meta);
      eval { $build->load_requires('share') };
    
      skip_all "configuration does not support $ext" if $@;
    
      if($ext eq 'tar.bz2')
      {
        skip_all 'Test requires ZLib support in Archive::Tar'
          unless eval { Archive::Tar->has_zlib_support };
      }
      elsif($ext eq 'tar.gz')
      {
        skip_all 'Test requires Bzip2 support in Archive::Tar'
          unless eval { Archive::Tar->has_bzip2_support };
      }
    
      my $archive = path("corpus/dist/foo-1.00.$ext")->absolute;
      
      my($out, $dir, $error) = capture_merged {
        my $dir = eval { $build->extract("$archive") };
        ($dir, $@);
      };
      
      my($bad1, $bad2);
      
      $bad1 = !!$error;
      is $error, '';

      note $out if $out ne '';
      
      if(defined $dir)
      {
        $dir = path($dir);

        $bad2 = !ok( defined $dir && -d $dir, "directory created"   );
        note "dir = $dir";

        foreach my $name (qw( configure foo.c ))
        {
          my $file = $dir->child($name);
          ok -f $file, "$name exists";
        }
      }
      
      if($bad1 || $bad2)
      {
        diag "failed with extension $ext";
        diag _dump({ error => $error, dir => "$dir" });
        if($out ne '')
        {
          diag "[out]";
          diag $out;
        }
      }
    }
  }
  
};

subtest 'archive with pax_global_header' => sub {

  skip_all 'Test requires Archive::Tar'
    unless eval q{ require Archive::Tar };

  my $build = alienfile_ok q{
  
    use alienfile;
    use Path::Tiny qw( path );
    probe sub { 'share' };
    share {
      download sub {
        my($build) = @_;
        path(__FILE__)->parent->parent->child('corpus/dist2/foo.tar')->absolute->copy('foo.tar');
      };
      plugin 'Extract::ArchiveTar';
    };
  
  };
  
  my $dir = alien_extract_ok;

  if(defined $dir)
  {
    my $file = path($dir)->child('foo.txt');
    my $content = eval { $file->slurp };
    is($content, "xx\n", "file content matches");
    
    unless(-f $file)
    {
      diag "listing:";
      foreach my $child (path($dir)->children)
      {
        diag $child;
      }
    }
    
  }

};

done_testing;
