use 5.008004;
use lib 't/lib';
use MyTest::FauxFetchCommand;
use MyTest::CaptureNote;
use MyTest::HTTP;
use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Fetch::Wget;
use Path::Tiny qw( path );
use Alien::Build::Util qw( _dump );
use JSON::PP qw( decode_json );

skip_all "No wget or not real wget" unless Alien::Build::Plugin::Fetch::Wget->_wget;

$Alien::Build::Plugin::Fetch::Wget::VERSION = '1.19';

subtest 'fetch from http' => sub {

  my $config = test_config 'httpd';

  skip_all 'Test requires httpd config' unless $config;

  my $base = $config->{url};

  my($proto) = $base =~ /^([a-z]+):/;
  like $proto, qr/^https?$/, "protocol is either http or https (url = $base)";

  # This test runs against a real http or ftp server, usually only in CI
  # the server is running on localhost
  local $ENV{ALIEN_DOWNLOAD_RULE} = $ENV{ALIEN_DOWNLOAD_RULE};
  $ENV{ALIEN_DOWNLOAD_RULE} = 'warn' if $proto ne 'https';

  my $build = alienfile_ok qq{
    use alienfile;

    meta->prop->{start_url} = '$base/html_test.html';

    probe sub { 'share' };

    share {
      plugin 'Fetch::Wget';
    };
  };

  alien_install_type_is 'share';

  subtest 'html' => sub {

    my $list = capture_note { $build->fetch };

    is(
      $list,
      hash {
        field type     => 'html';
        field base     => "$base/html_test.html";
        field content  => "<html><head><title>Hello World</title></head><body><p>Hello World</p></body></html>\n";
        field protocol => $proto;
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
        field protocol => $proto;
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

subtest 'headers' => sub {
  my $url = http_url;
  skip_all http_error unless $url;

  my $build = do {
    my $plugin = Alien::Build::Plugin::Fetch::Wget->new;
    my $build = alienfile filename => 'corpus/blank/alienfile';
    my $meta = $build->meta;
    $plugin->init($meta);
    $build;
  };

  require URI;
  my $furl = URI->new_abs("test1/foo.txt", $url);
  note "url = $furl";

  # This test runs against a real http or ftp server, usually only in CI
  # the server is running on localhost
  local $ENV{ALIEN_DOWNLOAD_RULE} = $ENV{ALIEN_DOWNLOAD_RULE};
  $ENV{ALIEN_DOWNLOAD_RULE} = 'warn' if $url ne 'https';

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

done_testing;
