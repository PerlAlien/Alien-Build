use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Prefer::SortVersions;
use Path::Tiny qw( path );
use Alien::Build::Util qw( _dump );

subtest 'updates requires' => sub {

  my $plugin = Alien::Build::Plugin::Prefer::SortVersions->new;

  my $build = alienfile filename => 'corpus/blank/alienfile';
  my $meta = $build->meta;
  
  $plugin->init($meta);
  
  is( $build->requires('share')->{'Sort::Versions'}, 0 );

  note _dump $meta;

};

subtest 'prefer' => sub {

  my $builder = sub {
    my $plugin = Alien::Build::Plugin::Prefer::SortVersions->new(@_);
    my $build = alienfile filename => 'corpus/blank/alienfile';
    my $meta = $build->meta;
    $plugin->init($meta);
    eval { $build->load_requires('share') };
    $@ ? () : wantarray ? ($build,$meta) : $build;
  };
  
  my $make_list = sub {
    return {
      type => 'list',
      list => [
        map {
          my $h = { filename => $_, url => "http://example.test/foo/bar/$_" };
        } @_
      ],
    };
  };

  my $make_cmp = sub {
    return {
      type => 'list',
      list => [
        map {
          hash {
            field filename => $_;
            field url => "http://example.test/foo/bar/$_";
            field version => T();
          },
        } @_
      ],
    };
  };

  skip_all 'test requires Sort::Versions' unless $builder->();

  subtest 'default settings' => sub {
  
    my $build = $builder->();
    
    my $res = $build->prefer($make_list->(qw(roger-0.0.0.tar.gz abc-2.3.4.tar.gz xyz-1.0.0.tar.gz)));
    is( $res, $make_cmp->(qw( abc-2.3.4.tar.gz xyz-1.0.0.tar.gz roger-0.0.0.tar.gz )) );
  
  };
  
  subtest 'filter' => sub {
  
    my $build = $builder->(filter => qr/abc|xyz/);
    my $res = $build->prefer($make_list->(qw(roger-0.0.0.tar.gz abc-2.3.4.tar.gz xyz-1.0.0.tar.gz)));
    is( $res, $make_cmp->(qw( abc-2.3.4.tar.gz xyz-1.0.0.tar.gz )) );
  
  };
  
  subtest 'version regex' => sub {
  
    my $build = $builder->(qr/^foo-[0-9\.]+-bar-([0-9\.](?:[0-9\.]*[0-9])?)/);
    my $res = $build->prefer($make_list->(qw( foo-10.0-bar-0.1.0.tar.gz foo-5-bar-2.1.0.tar.gz bogus.tar.gz )));
    is( $res, $make_cmp->(qw( foo-5-bar-2.1.0.tar.gz foo-10.0-bar-0.1.0.tar.gz )) );
    
  };

};

done_testing;
