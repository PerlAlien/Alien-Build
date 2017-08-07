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
    my $pick = Alien::Build::Plugin::Extract::Negotiate->_pick($ext);
    ok $pick, 'we have a pick';
    note "the pick is: $pick";
  }

};

done_testing;
