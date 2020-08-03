use 5.008004;
use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Extract::ArchiveTar;
use Path::Tiny qw( path );
use Capture::Tiny qw( capture_merged );
use File::Temp qw( tempdir );
use Alien::Build::Util qw( _dump );

subtest 'available' => sub {

  subtest 'zip' => sub {

    # should always be false...
    is(Alien::Build::Plugin::Extract::ArchiveTar->available('zip'), F());

  };

  subtest 'tar' => sub {

    # should always be true...
    is(Alien::Build::Plugin::Extract::ArchiveTar->available('tar'), T());

  };

  subtest 'tar.gz' => sub {

    my $has_it;

    skip_all 'test requires Archive::Tar with has_zlib_support' unless eval { require Archive::Tar; Archive::Tar->can('has_zlib_support') };

    my $mock = mock 'Archive::Tar' => (
      override => [
        has_zlib_support => sub {
          note "has_it = $has_it";
          $has_it;
        },
      ],
    );

    subtest 'has it' => sub {

      $has_it = 1;

      is(Alien::Build::Plugin::Extract::ArchiveTar->available('tar.gz'), T());

    };

    subtest 'does not' => sub {

      $has_it = 0;

      is(Alien::Build::Plugin::Extract::ArchiveTar->available('tar.gz'), F());

    };

  };

  subtest 'tar.bz2' => sub {

    my $has_it;

    skip_all 'test requires Archive::Tar with has_bzip2_support' unless eval { require Archive::Tar; Archive::Tar->can('has_bzip2_support') };

    my $mock = mock 'Archive::Tar' => (
      override => [
        has_bzip2_support => sub {
          note "has_it = $has_it";
          $has_it;
        },
      ],
    );

    todo 'detection in Archive::Tar is sometimes broken' => sub {

      subtest 'has it' => sub {

        $has_it = 1;

        is(Alien::Build::Plugin::Extract::ArchiveTar->available('tar.bz2'), T());

      };

      subtest 'does not' => sub {

        $has_it = 0;

        is(Alien::Build::Plugin::Extract::ArchiveTar->available('tar.bz2'), F());

      };
    };

  };

};

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
          unless eval { require Alien::Build::Plugin::Extract::ArchiveTar; Alien::Build::Plugin::Extract::ArchiveTar->_can_bz2 };
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
    unless eval { require Archive::Tar };

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
