use 5.008004;
use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Fetch::LWP;
use lib 't/lib';
use Path::Tiny qw( path );
use MyTest::HTTP;
use MyTest::FTP;
use MyTest::File;
use MyTest::CaptureNote;
use Alien::Build::Util qw( _dump );
use JSON::PP qw( decode_json );

subtest 'updates requires' => sub {

  my $plugin = Alien::Build::Plugin::Fetch::LWP->new( url => 'file://localhost/' );

  my $build = alienfile filename => 'corpus/blank/alienfile';
  my $meta = $build->meta;

  $plugin->init($meta);

  is( $build->requires('share')->{'LWP::UserAgent'}, 0 );

  note _dump $meta;

};

subtest 'use start_url' => sub {

  subtest 'sets start_url' => sub {

    my $build = alienfile_ok q{

      use alienfile;

      plugin 'Fetch::LWP' => 'http://foo.bar.baz';

    };

    is $build->meta_prop->{start_url}, 'http://foo.bar.baz';

  };

  subtest 'uses start_url' => sub {

    my $mock = mock 'Alien::Build::Plugin::Fetch::LWP';
    my $plugin;

    $mock->after(init => sub {
      my($self, $meta) = @_;
      $plugin = $self;
    });

    my $build = alienfile_ok q{

      use alienfile;

      meta->prop->{start_url} = 'http://baz.bar.foo';

      plugin 'Fetch::LWP';

    };

    is $plugin->url, 'http://baz.bar.foo';

  };

};

subtest 'fetch' => sub {

  skip_all 'test requires LWP::UserAgent' unless eval { require LWP::UserAgent; 1 };

  foreach my $type (qw( http ftp file ))
  {
    subtest "with $type" => sub {

      my $url = do {
        my $get_url = \&{"${type}_url"};
        my $error   = \&{"${type}_error"};
        my $url = $get_url->();
        skip_all $error->() unless $url;
      };

      # This test runs against a real http or ftp server, usually only in CI
      # the server is running on localhost
      local $ENV{ALIEN_DOWNLOAD_RULE} = $ENV{ALIEN_DOWNLOAD_RULE};
      $ENV{ALIEN_DOWNLOAD_RULE} = 'warn' if $url =~ /^(http|ftp):/;

      my $plugin = Alien::Build::Plugin::Fetch::LWP->new( url => "$url" );
      my $build = alienfile filename => 'corpus/blank/alienfile';
      my $meta = $build->meta;

      $plugin->init($meta);
      eval { $build->load_requires('share') };
      skip_all 'test requires LWP' if $@;

      subtest 'listing' => sub {
        my $res = $build->fetch;
        is(
          $res,
          hash {
            if($type eq 'ftp')
            {
              field type => 'dir_listing';
            }
            else
            {
              field type    => 'html';
              field charset => E();
            }
            field base     => match qr!^$type:/!;
            field content  => match qr!foo-1\.00\.tar\.gz!;
            field protocol => $type;
            end;
          },
         ) || diag _dump($res);
      };

      subtest 'file' => sub {
        my $furl = URI->new_abs("foo-1.00.tar.gz", $url);
        note "url = $furl";

        my $expected_content = path('corpus/dist/foo-1.00.tar.gz')->slurp_raw;

        my $res = $build->fetch("$furl");
        is(
          $res,
          hash {
            field type     => 'file';
            field filename => 'foo-1.00.tar.gz';
            field content  => $expected_content;
            field protocol => $type;
            end;
          },
        );
      };

      subtest 'not found' => sub {
        my $furl = URI->new_abs("bogus.tar.gz", $url);
        note "url = $furl";
        eval { $build->fetch("$furl") };
        like $@, qr/^error fetching $type:/;
      };
    };
  }

  subtest 'headers' => sub {
    my $url = http_url;
    skip_all http_error unless $url;

    require URI;
    my $furl = URI->new_abs("test1/foo.txt", $url);
    note "url = $furl";

    # This test runs against a real http or ftp server, usually only in CI
    # the server is running on localhost
    local $ENV{ALIEN_DOWNLOAD_RULE} = $ENV{ALIEN_DOWNLOAD_RULE};
    $ENV{ALIEN_DOWNLOAD_RULE} = 'warn' if $url ne 'https';

    my $build = do {
      my $plugin = Alien::Build::Plugin::Fetch::LWP->new( url => "$url" );
      my $build = alienfile filename => 'corpus/blank/alienfile';
      my $meta = $build->meta;
      $plugin->init($meta);
      $build;
    };

    my $res = capture_note { $build->fetch("$furl", http_headers => [ Foo => 'Bar1', Foo => 'Bar2', Baz => 1 ]) };

    my $content;
    is
      $content = decode_json($res->{content}),
      hash {
        field headers => hash {
          field Foo => 'Bar1, Bar2';
          field Baz => 1;
          etc;
        };
        etc;
      },
    ;

    note _dump($content);
  };

};

done_testing;
