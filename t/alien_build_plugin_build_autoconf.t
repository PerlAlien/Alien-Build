use lib 'corpus/lib';
use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Build::Autoconf;
use Alien::Build::Util qw( _dump );
use Path::Tiny qw( path );

subtest 'basic' => sub {

  my $plugin = Alien::Build::Plugin::Build::Autoconf->new;
  isa_ok $plugin, 'Alien::Build::Plugin';
  isa_ok $plugin, 'Alien::Build::Plugin::Build::Autoconf';

  my $build = alienfile_ok q{ use alienfile };
  my $meta = $build->meta;
  
  $plugin->init($meta);
  
  my $configure = $meta->interpolator->interpolate('%{configure}');
  isnt $configure, '', "\%{configure} = $configure";
  like $configure, qr{configure};
  like $configure, qr{--with-pic};
  
  is($build->meta_prop->{destdir}, 1);
  is($meta->prop->{destdir}, 1);
};

subtest 'turn off --with-pic' => sub {

  my $plugin = Alien::Build::Plugin::Build::Autoconf->new( with_pic => 0 );

  is( $plugin->with_pic, 0 );
  
  my $build = alienfile_ok q{ use alienfile };
  my $meta = $build->meta;
  
  $plugin->init($meta);

  my $configure = $meta->interpolator->interpolate('%{configure}');
  isnt $configure, '', "\%{configure} = $configure";
  like $configure, qr{configure$};

};

subtest 'out-of-source' => sub {

  local $Alien::Build::VERSION = '1.08';

  my $build = alienfile_ok q{
    use alienfile;
    use Alien::Build::Util qw( _dump );
    use Path::Tiny qw( path );
    
    share {
      meta->prop->{out_of_source} = 1;
      plugin 'Download::Foo';
      plugin 'Build::Autoconf' => (
        with_pic => 0,
      );
      build sub {
        my($build) = @_;
        $build->log(_dump($build->install_prop));
        path('file1')->touch;

        my $prefix = $build->install_prop->{prefix};
        $prefix =~ s{^([a-z]):/}{$1/}i if $^O eq 'MSWin32';

        $build->log("prefix = $prefix");        
        my $file2 = path($ENV{DESTDIR})->child($prefix)->child('file2');
        $file2->parent->mkpath;
        $file2->touch;
      };
    };
  };
  
  $build->load_requires('share');

  note _dump($build->install_prop);

  subtest 'before build' => sub {
    my $configure = $build->meta->interpolator->interpolate('%{configure}');
    note "%{configure} = $configure";
    ok 1;
  };
  
  alien_build_ok;
  
  note _dump($build->install_prop);

  subtest 'after build' => sub {
    my $configure = $build->meta->interpolator->interpolate('%{configure}');
    note "%{configure} = $configure";

    my $regex = $^O eq 'MSWin32' ? qr/^sh (.*?)\s/ : qr/^(.*)\s/;
    like $configure, $regex, 'matches';

    if($configure =~ $regex)
    {
      my $path = path($1);
      ok(-f $path, "configure is in the right spot" );
      ok(-f $path->sibling('foo.c'), "foo.c is in the right spot" );
    }

  };
};

done_testing;

{
  package
    Alien::MSYS;
    
  use File::Temp qw( tempdir );

  BEGIN {
    our $VERSION = '0.07';
    $INC{'Alien/MSYS.pm'} = __FILE__;
  }

  my $path;

  sub msys_path
  {
    if(!$path)
    {
      $path = tempdir( CLEANUP => 1);
    }
    $path;
  }
  
}
