use 5.008004;
use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Extract::Directory;
use Path::Tiny qw( path );
use Capture::Tiny qw( capture_merged );

subtest 'handles' => sub {

  is(
    Alien::Build::Plugin::Extract::Directory->handles('d'),
    T(),
  );

  is(
    Alien::Build::Plugin::Extract::Directory->handles('tar'),
    F(),
  );

};

subtest 'available' => sub {

  is(
    Alien::Build::Plugin::Extract::Directory->available('d'),
    T(),
  );

  is(
    Alien::Build::Plugin::Extract::Directory->available('tar'),
    F(),
  );

};

subtest 'basic' => sub {

  # Test uses download directory, which is unsupported by
  # digest checks
  local $ENV{ALIEN_DOWNLOAD_RULE} = 'warn';

  my $build = alienfile_ok q{
    use alienfile;
    use Path::Tiny qw( path );
    plugin 'Extract::Directory';
  };

  $build->install_prop->{download} = path('corpus/dist/foo-1.00')->absolute->stringify;

  my($out, $dir) = capture_merged { $build->extract };

  $dir = path($dir);

  ok( defined $dir && -d $dir, "directory created"   );
  note "dir = $dir";

  foreach my $name (qw( configure foo.c ))
  {
    my $file = $dir->child($name);
    ok -f $file, "$name exists";
  }

};

done_testing;
