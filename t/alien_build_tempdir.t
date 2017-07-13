use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build;
use File::Temp qw( tempdir );
use Path::Tiny qw( path );

my $build = alienfile filename => 'corpus/blank/alienfile';

ok(
  -d $build->root,
  "root = @{[ $build->root ]}",
);

subtest 'cleanup on empty' => sub {

  my $tmpdir = Alien::Build::TempDir->new($build, "foo");
  
  ok( -d "$tmpdir", "tempdir = $tmpdir" );
  
  my $str = "$tmpdir";
  
  undef $tmpdir;
  
  ok( ! -d "$str", "directory removed" );

};

subtest 'do not cleanup non-empty' => sub {

  my $tmpdir = Alien::Build::TempDir->new($build, "bar");

  ok( -d "$tmpdir", "tempdir = $tmpdir" );
  
  my $str = "$tmpdir";
  
  path("$str")->child('baz.txt')->touch;
  
  undef $tmpdir;
  
  ok( -d "$str", "directory not removed" );
  
};

done_testing;

