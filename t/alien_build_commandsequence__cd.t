use Test2::V0 -no_srand => 1;
use Alien::Build::CommandSequence;
use Test::Alien::Build;
use File::chdir;
use File::Temp qw( tempdir );
use Path::Tiny qw( path );
use Capture::Tiny qw( capture_merged );

my $build = alienfile q{ use alienfile };

subtest 'cd list' => sub {

  local $Alien::Build::VERSION = '1.05';

  local $CWD;

  my $where;

  my $dir = path(tempdir( CLEANUP => 1 ))->child('foo')->canonpath;

  my $seq = Alien::Build::CommandSequence->new(
    [ "%{make_path} $dir" ],
    [ "cd", "$dir" ],
    sub { path('foo.txt')->spew('here') },
  );
  
  note scalar capture_merged { $seq->execute($build) };
  
  my $foo_txt = path($dir)->child('foo.txt');
  
  is( -f $foo_txt, T(), "created file" );
  is( $foo_txt->slurp, "here", "content" );

};

subtest 'cd list' => sub {

  local $Alien::Build::VERSION = '1.05';

  local $CWD;

  my $where;

  my $dir = path(tempdir( CLEANUP => 1 ))->child('foo')->canonpath;
  
  my $seq = Alien::Build::CommandSequence->new(
    [ "%{make_path} $dir" ],
    "cd $dir",
    sub { path('foo.txt')->spew('here') },
  );
  
  note scalar capture_merged { $seq->execute($build) };
  
  my $foo_txt = path($dir)->child('foo.txt');
  
  is( -f $foo_txt, T(), "created file" );
  is( $foo_txt->slurp, "here", "content" );

};

subtest 'cd list with code ref' => sub {

  local $Alien::Build::VERSION = '1.05';

  local $CWD;

  my $where;

  my $dir = path(tempdir( CLEANUP => 1 ))->child('foo')->canonpath;
  
  my $seq = Alien::Build::CommandSequence->new(
    [ "%{make_path} $dir" ],
    [ "cd", "$dir", sub { path('foo.txt')->spew('here') } ],
  );
  
  note scalar capture_merged { $seq->execute($build) };
  
  my $foo_txt = path($dir)->child('foo.txt');
  
  is( -f $foo_txt, T(), "created file" );
  is( $foo_txt->slurp, "here", "content" );

};

done_testing;
