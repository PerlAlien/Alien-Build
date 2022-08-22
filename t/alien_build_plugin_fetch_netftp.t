use 5.008004;
use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Fetch::NetFTP;
use lib 't/lib';
use MyTest::FTP;
use Path::Tiny qw( path );
use Alien::Build::Util qw( _dump );

subtest 'updates requires' => sub {

  my $plugin = Alien::Build::Plugin::Fetch::NetFTP->new( url => 'ftp://localhost/' );

  my $build = alienfile filename => 'corpus/blank/alienfile';
  my $meta = $build->meta;

  $plugin->init($meta);

  is( $build->requires('share')->{'Net::FTP'}, 0 );
  is( $build->requires('share')->{'URI'}, 0 );

  note _dump $meta;

};

subtest 'use start_url' => sub {

  subtest 'sets start_url' => sub {

    my $build = alienfile_ok q{

      use alienfile;

      plugin 'Fetch::NetFTP' => 'http://foo.bar.baz';

    };

    is $build->meta_prop->{start_url}, 'http://foo.bar.baz';

  };

  subtest 'uses start_url' => sub {

    my $mock = mock 'Alien::Build::Plugin::Fetch::NetFTP';
    my $plugin;

    $mock->after(init => sub {
      my($self, $meta) = @_;
      $plugin = $self;
    });

    my $build = alienfile_ok q{

      use alienfile;

      meta->prop->{start_url} = 'http://baz.bar.foo';

      plugin 'Fetch::NetFTP';

    };

    is $plugin->url, 'http://baz.bar.foo';

  };

};

subtest 'fetch' => sub {

  my $url = ftp_url;

  unless($url)
  {
    my $log = path('t/bin/ftpd.log');
    if(-r $log)
    {
      note($log->slurp);
    }
    skip_all ftp_error;
  }

  note "url = $url";

  my $plugin = Alien::Build::Plugin::Fetch::NetFTP->new( url => $url );

  my $build = alienfile filename => 'corpus/blank/alienfile';
  my $meta = $build->meta;

  $plugin->init($meta);

  eval { $build->load_requires('share') };
  skip_all 'test requires Net::FTP and URI' if $@;

  subtest 'listing' => sub {
    my $res = $build->fetch;
    is(
      $res,
      hash {
        field type     => 'list';
        field protocol => 'ftp';
        field list => array {
          for (qw( foo-1.00 foo-1.00.tar foo-1.00.tar.Z foo-1.00.tar.bz2 foo-1.00.tar.gz foo-1.00.tar.xz foo-1.00.zip )) {
            item hash {
              field filename => $_;
              field url      => match qr!^ftp://!;
            };
          }
        };
      }
    );
  };

  subtest 'file' => sub {
    my $furl = URI->new_abs("foo-1.00.tar.gz", $url);
    note "url = $furl";

    my $res = $build->fetch($furl);
    is(
      $res,
      hash {
        field type     => 'file';
        field protocol => 'ftp';
        field filename => 'foo-1.00.tar.gz';
        field path     => match qr/foo-1\.00\.tar\.gz$/;
      },
    );

    my $expected = path('corpus/dist/foo-1.00.tar.gz')->slurp_raw;
    my $actual = path($res->{path})->slurp_raw;
    is( $actual, $expected );
  };

  subtest 'not found' => sub {
    my $furl = URI->new_abs("bogus.tar.gz", $url);
    note "url = $furl";
    eval { $build->fetch("$furl") };
    like $@, qr/^unable to fetch ftp/;
  };

};

done_testing;
