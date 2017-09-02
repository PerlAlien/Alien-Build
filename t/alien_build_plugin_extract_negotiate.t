use Test2::Require::Module 'Archive::Tar' => 0;
use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Extract::Negotiate;
use Capture::Tiny qw( capture_merged );
use Path::Tiny qw( path );

subtest basic => sub {

  my $build = alienfile q{
  
    use alienfile;
    
    probe sub { 'share' };
    
    share {
    
      plugin 'Download' => 'corpus/dist/foo-1.00.tar';
      plugin 'Extract' => ();
    
    };
    
  };
  
  note scalar capture_merged {
    $build->load_requires($build->install_type);
    $build->download;
  };
  
  my $dir = $build->extract;
  
  ok(-d $dir, "extracted to directory");
  note "dir = $dir";

  foreach my $filename (qw( configure foo.c ))
  {
    my $old  = path('corpus/dist/foo-1.00')->child($filename);
    my $new  = path($dir)->child($filename);
    
    ok(-f $new, "created file $filename");
    
    is($new->slurp, $old->slurp, 'content matches');
  }

};

subtest 'picks' => sub {

  foreach my $ext (qw( tar tar.gz tar.bz2 zip d ))
  {
    my $pick = Alien::Build::Plugin::Extract::Negotiate->pick($ext);
    ok $pick, 'we have a pick';
    note "the pick is: $pick";
  }

  subtest 'tar' => sub {
  
    subtest 'plain' => sub {
      # always
      is(
        Alien::Build::Plugin::Extract::Negotiate->pick('tar'),
        'Extract::ArchiveTar',
      );
    };
    
    my %available;
    
    my $mock = Test2::Mock->new(
      class => 'Alien::Build::Plugin::Extract::ArchiveTar',
      override => [
        available => sub {
          my(undef, $format) = @_;
          note "$format is available = @{[ !! $available{$format} ]}";
          !!$available{$format};
        },
      ]
    );
    
    subtest 'tar.gz' => sub {
    
      %available = ( 'tar.gz' => 1 );

      is(
        Alien::Build::Plugin::Extract::Negotiate->pick('tar.gz'),
        'Extract::ArchiveTar',
        'when avail',
      );

      %available = ( 'tar.gz' => '' );

      is(
        Alien::Build::Plugin::Extract::Negotiate->pick('tar.gz'),
        'Extract::CommandLine',
        'when not',
      );

    };
  };
  
  subtest 'zip' => sub {
  
    my $have_archive_zip = 0;
    my $have_info_zip    = 0;
    
    my $mock1 = Test2::Mock->new(
      class => 'Alien::Build::Plugin::Extract::ArchiveZip',
      override => [
        available => sub {
          my(undef, $format) = @_;
          !!($format eq 'zip' && $have_archive_zip);
        },
      ],
    );
    

    my $mock2 = Test2::Mock->new(
      class => 'Alien::Build::Plugin::Extract::CommandLine',
      override => [
        available => sub {
          my(undef, $format) = @_;
          !!($format eq 'zip' && $have_info_zip);
        },
      ],
    );
    
    subtest 'nada' => sub {
    
      is(
        Alien::Build::Plugin::Extract::Negotiate->pick('zip'),
        'Extract::ArchiveZip',
      );
    
    };

    subtest 'just Archive::Zip' => sub {
    
      $have_archive_zip = 1;
      $have_info_zip    = 0;
    
      is(
        Alien::Build::Plugin::Extract::Negotiate->pick('zip'),
        'Extract::ArchiveZip',
      );
    
    };

    subtest 'just info zip' => sub {
    
      $have_archive_zip = 0;
      $have_info_zip    = 1;
    
      is(
        Alien::Build::Plugin::Extract::Negotiate->pick('zip'),
        'Extract::CommandLine',
      );
    
    };

    subtest 'both' => sub {
    
      $have_archive_zip = 1;
      $have_info_zip    = 1;
    
      # Not 100% sure this is the best choice now that I think of it.
      is(
        Alien::Build::Plugin::Extract::Negotiate->pick('zip'),
        'Extract::ArchiveZip',
      );
    
    };
    
  
  };
  
};

done_testing;
