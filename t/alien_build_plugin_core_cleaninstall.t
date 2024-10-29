use 5.008004;
use Test2::V0 -no_srand => 1;
use Alien::Build::Plugin::Core::CleanInstall;
use Test::Alien::Build;
use Path::Tiny qw( path );

subtest 'basic' => sub {

  my $build = alienfile_ok q{
    use alienfile;
    probe sub { 'share' };
  };

  my $dir = path($build->runtime_prop->{prefix});

  $dir->child($_)->mkpath for qw( _alien bin include lib );
  $dir->child('foo.txt')->touch;
  $dir->child('_alien/alienfile')->touch;
  $dir->child('bin/myexe')->touch;
  $dir->child('include/myheader.h')->touch;
  $dir->child('lib/libfoo.a')->touch;

  alien_clean_install;

  ok  -d "$dir/_alien";
  ok  -f "$dir/_alien/alienfile";
  ok !-e "$dir/foo.txt";
  ok !-e "$dir/bin/myexe";
  ok !-e "$dir/include/myheader.h";
  ok !-e "$dir/lib/libfoo.a";
};

subtest 'do remove on system install' => sub {

  my $build = alienfile_ok q{
    use alienfile;
    probe sub { 'system' };
  };

  my $dir = path($build->runtime_prop->{prefix});

  $dir->child($_)->mkpath for qw( _alien bin include lib );
  $dir->child('foo.txt')->touch;
  $dir->child('_alien/alienfile')->touch;
  $dir->child('bin/myexe')->touch;
  $dir->child('include/myheader.h')->touch;
  $dir->child('lib/libfoo.a')->touch;

  alien_clean_install;

  ok  -d "$dir/_alien";
  ok  -f "$dir/_alien/alienfile";
  ok  !-e "$dir/foo.txt";
  ok  !-e "$dir/bin/myexe";
  ok  !-e "$dir/include/myheader.h";
  ok  !-e "$dir/lib/libfoo.a";
};

subtest 'do not try to remove when it isn\'t there' => sub {

  my $build = alienfile_ok q{
    use alienfile;
    probe sub { 'share' };
  };

  path($build->runtime_prop->{prefix})->remove_tree;

  alien_clean_install;

};

done_testing;
