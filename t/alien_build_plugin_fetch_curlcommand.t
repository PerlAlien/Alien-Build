use 5.008004;
use lib 't/lib';
use MyTest::FauxFetchCommand;
use MyTest::HTTP;
use MyTest::CaptureNote;
use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Fetch::CurlCommand;
use Path::Tiny qw( path );
use Capture::Tiny ();
use JSON::PP ();
use File::Which qw( which );
use Alien::Build::Util qw( _dump );
use JSON::PP qw( decode_json );

$Alien::Build::Plugin::Fetch::CurlCommand::VERSION = '1.19';

# This test makes real http request against localhost only
$ENV{ALIEN_DOWNLOAD_RULE} = 'warn';

subtest 'fetch from http' => sub {

  my $config = test_config 'httpd';

  skip_all 'Test requires httpd config' unless $config;

  my $base = $config->{url};

  my $build = alienfile_ok qq{
    use alienfile;

    meta->prop->{start_url} = '$base/html_test.html';

    probe sub { 'share' };

    share {
      plugin 'Fetch::CurlCommand';
    };
  };

  alien_install_type_is 'share';

  subtest 'directory listing' => sub {

    my $list = capture_note { $build->fetch };

    is(
      $list,
      hash {
        field type     => 'html';
        field base     => "$base/html_test.html";
        field content  => "<html><head><title>Hello World</title></head><body><p>Hello World</p></body></html>\n";
        field protocol => 'http';
        end;
      },
      'list'
    );

  };

  subtest 'file' => sub {

    my $file = capture_note { $build->fetch("$base/foo-1.01.tar") };

    is(
      $file,
      hash {
        field type     => 'file';
        field filename => 'foo-1.01.tar';
        field path     => T();
        field protocol => 'http';
        end;
      },
      'file meta',
    );

    is(
      scalar path($file->{path})->slurp,
      "content:foo-1.01\n",
      'file content',
    );

  };

  subtest '404' => sub {

    my($file, $error) = capture_note {
      my $file = eval {
        $build->fetch("$base/bogus.html");
      };
      ($file, $@);
    };

    isnt $error, '', 'throws error';
    note "error is: $error";

  };

};

#subtest 'fetch from ftp' => sub {
#
#  my $config = test_config 'ftpd';
#
#  skip_all 'Test requires ftp config' unless $config;
#
#  my $base = $config->{url};
#
#  my $build = alienfile_ok qq{
#    use alienfile;
#
#    meta->prop->{start_url} = '$base/html_test.html';
#
#    probe sub { 'share' };
#
#    share {
#      plugin 'Fetch::CurlCommand';
#    };
#  };
#
#  alien_install_type_is 'share';
#
#  subtest 'get directory listing with trailing slash' => sub {
#
#    my $list = capture_note { $build->fetch("$base/") };
#
#    is(
#      $list,
#      hash {
#        field type => 'list';
#        field list => array {
#          foreach my $filename (qw( foo-1.00.tar foo-1.01.tar foo-1.02.tar html_test.html ))
#          {
#            item hash {
#              field filename => $filename;
#              field url      => "$base/$filename";
#              end;
#            };
#          };
#          end;
#        };
#      },
#      'list',
#    );
#
#  };
#
#  subtest 'get non-existant directory listing with trailing slash' => sub {
#
#    my $error = capture_note {
#      eval {
#        $build->fetch("$base/bogus/")
#      };
#      $@;
#    };
#
#    isnt $error, '', 'throws error';
#    note "error = $error";
#
#  };
#
#  subtest 'get file' => sub {
#
#    my $file = capture_note { $build->fetch("$base/foo-1.01.tar") };
#
#    is(
#      $file,
#      hash {
#        field type     => 'file';
#        field filename => 'foo-1.01.tar';
#        field path     => T();
#        end;
#      },
#      'file meta',
#    );
#
#    is(
#      scalar path($file->{path})->slurp,
#      "content:foo-1.01\n",
#      'file content',
#    );
#
#  };
#
#  subtest 'get missing file' => sub {
#
#    my($error) = capture_note {
#      eval {
#        $build->fetch("$base/bogus.txt");
#      };
#      $@;
#    };
#
#    isnt $error, '', 'throws error';
#    note "error is : $error";
#
#  };
#
#  subtest 'get directory listing sans trailing slash' => sub {
#
#    my $list = capture_note { $build->fetch("$base") };
#
#    is(
#      $list,
#      hash {
#        field type => 'list';
#        field list => array {
#          foreach my $filename (qw( foo-1.00.tar foo-1.01.tar foo-1.02.tar html_test.html ))
#          {
#            item hash {
#              field filename => $filename;
#              field url      => "$base/$filename";
#              end;
#            };
#          };
#          end;
#        };
#      },
#      'list',
#    );
#
#  };
#
#};

subtest 'live test' => sub {
  skip_all 'set ALIEN_BUILD_LIVE_TEST=1 to enable test' unless $ENV{ALIEN_BUILD_LIVE_TEST};

  if(defined $ENV{CIPDIST} && $ENV{CIPDIST} eq 'centos6')
  {
    my $curl = which('curl');
    is $curl, T();
    note "curl = $curl";
    my $pok = Alien::Build::Plugin::Fetch::CurlCommand->protocol_ok('https');
    is $pok, F();
    return;
  }
  else
  {
    my $curl = which('curl');
    is $curl, T();
    note "curl = $curl";
    my $pok = Alien::Build::Plugin::Fetch::CurlCommand->protocol_ok('https');
    is $pok, T();
  }

  require Alien::Build::Plugin::Download::Negotiate;
  my $mock = mock 'Alien::Build::Plugin::Download::Negotiate' => (
    override => [
      pick => sub {
        ('Fetch::CurlCommand', 'Decode::Mojo');
      },
    ],
  );

  alienfile_ok q{
    use alienfile;

    probe sub { 'share' };

    share {

      plugin Download => (
        url => 'https://alienfile.org/dontpanic/',
        version => qr/([0-9\.]+)\.tar\.gz$/,
      );

    };
  };

  my $download = alien_download_ok;

  ok -f $download,  "file exists";

  is
    path($download)->basename,
    match qr/^dontpanic-.*\.tar\.gz$/;
};

subtest 'headers' => sub {
  my $url = http_url;
  skip_all http_error unless $url;

  my $build = do {
    my $plugin = Alien::Build::Plugin::Fetch::CurlCommand->new( url => "$url" );
    my $build = alienfile filename => 'corpus/blank/alienfile';
    my $meta = $build->meta;
    $plugin->init($meta);
    $build;
  };

  require URI;
  my $furl = URI->new_abs("test1/foo.txt", $url);
  note "url = $furl";

  my $res = capture_note { $build->fetch("$furl", http_headers => [ Foo => 'Bar1', Foo => 'Bar2', Baz => 1 ]) };

  note _dump($res);

  my $content;
  is
    $content = decode_json(path($res->{path})->slurp_raw),
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

done_testing
