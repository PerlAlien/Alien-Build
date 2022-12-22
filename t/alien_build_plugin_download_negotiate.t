use 5.008004;
use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Download::Negotiate;
use Alien::Build::Plugin::Fetch::CurlCommand;
use Path::Tiny;
use Capture::Tiny qw( capture_merged );
use Alien::Build::Util qw( _dump );

delete $ENV{$_} for qw( ftp_proxy all_proxy );

my $mock_pick_decoder = mock 'Alien::Build::Plugin::Download::Negotiate' => (
  override => [
    _pick_decoder => sub { 'Decode::Mojo' },
  ],
);

subtest 'pick fetch' => sub {

  local %ENV = %ENV;
  my $has_ssl = 0;
  my $mock = mock 'Alien::Build::Plugin::Download::Negotiate' => (
    override => [
      _has_ssl => sub { $has_ssl },
    ],
  );

  my %curl;
  my $mock2 = mock 'Alien::Build::Plugin::Fetch::CurlCommand' => (
    override => [
      protocol_ok => sub {
        my(undef, $protocol) = @_;
        $curl{$protocol};
      }
    ]
  );

  subtest 'http' => sub {

    my $plugin = Alien::Build::Plugin::Download::Negotiate->new('http://mytest.test/');

    is([$plugin->pick], ['Fetch::HTTPTiny','Decode::Mojo']);
    is($plugin->scheme, 'http');

  };

  subtest 'http override decoder scalar' => sub {

    { package Alien::Build::Plugin::Foo::Bar;
      use Alien::Build::Plugin;

      sub init {}
    }

    my $plugin = Alien::Build::Plugin::Download::Negotiate->new( url => 'http://mytest.test/', decoder => 'Foo::Bar' );

    is([$plugin->pick], ['Fetch::HTTPTiny','Foo::Bar']);
    is($plugin->scheme, 'http');

  };

  subtest 'http override decoder array' => sub {

    { package Alien::Build::Plugin::Foo::Baz;
      use Alien::Build::Plugin;

      sub init {}
    }

    my $plugin = Alien::Build::Plugin::Download::Negotiate->new( url => 'http://mytest.test/', decoder => ['Foo::Bar','Foo::Baz'] );

    is([$plugin->pick], ['Fetch::HTTPTiny','Foo::Bar', 'Foo::Baz']);
    is($plugin->scheme, 'http');

  };

  subtest 'https (ssl modules already installed)' => sub {

    $has_ssl = 1;
    %curl = ( https => 1 );

    my $plugin = Alien::Build::Plugin::Download::Negotiate->new('https://mytest.test/');

    is([$plugin->pick], ['Fetch::HTTPTiny','Decode::Mojo']);
    is($plugin->scheme, 'https');

  };

  subtest 'https (ssl modules NOT already installed)' => sub {

    skip_all 'not picking curl for now :(';
    $has_ssl = 0;
    %curl = ( https => 1 );

    my $plugin = Alien::Build::Plugin::Download::Negotiate->new('https://mytest.test/');

    is([$plugin->pick], ['Fetch::CurlCommand','Decode::Mojo']);
    is($plugin->scheme, 'https');

  };

  subtest 'https (ssl modules NOT already installed, no curl)' => sub {

    $has_ssl = 0;
    %curl = ( https => 0 );

    my $plugin = Alien::Build::Plugin::Download::Negotiate->new('https://mytest.test/');

    is([$plugin->pick], ['Fetch::HTTPTiny','Decode::Mojo']);
    is($plugin->scheme, 'https');

  };

  subtest 'ftp direct' => sub {

    my $plugin = Alien::Build::Plugin::Download::Negotiate->new('ftp://mytest.test/');

    is([$plugin->pick], ['Fetch::NetFTP']);
    is($plugin->scheme, 'ftp');

  };

  subtest 'ftp direct proxy' => sub {

    $ENV{ftp_proxy} = 1;

    my $plugin = Alien::Build::Plugin::Download::Negotiate->new('ftp://mytest.test/');

    is([$plugin->pick], ['Fetch::LWP','Decode::DirListing','Decode::Mojo']);
    is($plugin->scheme, 'ftp');

  };

  subtest 'local file URI' => sub {

    $ENV{ftp_proxy} = 1;

    my $plugin = Alien::Build::Plugin::Download::Negotiate->new('file:///foo/bar/baz');

    is([$plugin->pick], ['Fetch::Local']);
    is($plugin->scheme, 'file');

  };

  subtest 'local file' => sub {

    $ENV{ftp_proxy} = 1;

    my $plugin = Alien::Build::Plugin::Download::Negotiate->new('/foo/bar/baz');

    is([$plugin->pick], ['Fetch::Local']);
    is($plugin->scheme, 'file');

  };

  subtest 'bootstrap ssl' => sub {

    subtest 'without Net::SSLeay' => sub {

      $has_ssl = 0;
      %curl = ();

      my $plugin = Alien::Build::Plugin::Download::Negotiate->new(
        url           => 'https://mytest.test/',
        bootstrap_ssl => 1,
      );

      is(
        [$plugin->pick],
        array {
          item ['Fetch::CurlCommand','Fetch::Wget'];
          item 'Decode::Mojo';
          end;
        },
      );
    };

    subtest 'with Net::SSLeay' => sub {

      $has_ssl = 1;
      %curl = ();

      my $plugin = Alien::Build::Plugin::Download::Negotiate->new(
        url           => 'https://mytest.test/',
        bootstrap_ssl => 1,
      );

      is(
        [$plugin->pick],
        array {
          item 'Fetch::HTTPTiny';
          item 'Decode::Mojo';
          end;
        },
      );

    };

  };

  subtest 'bootstrap ssl http' => sub {

    my $plugin = Alien::Build::Plugin::Download::Negotiate->new(
      url           => 'http://mytest.test/',
      bootstrap_ssl => 1,
    );

    is(
      [$plugin->pick],
      array {
        item 'Fetch::HTTPTiny';
        item 'Decode::Mojo';
        end;
      },
    );

  };

};

subtest 'get the version' => sub {

  skip_all 'test requires Sort::Versions'
    unless eval { require Sort::Versions; 1 };

  my $build = alienfile q{
    use alienfile;
    probe sub { 'share' };
    plugin 'Download' => (
      url => 'corpus/dist',
      version => qr/([0-9\.]+)/,
      filter => qr/\.tar\.gz$/,
    );
  };

  note capture_merged {
    $build->download;
    ();
  };

  is($build->runtime_prop->{version}, '1.00');

  my $filename = $build->install_prop->{download};

  ok(-f $filename, "tarball downloaded");
  note "filename = $filename";

  my $orig = path('corpus/dist/foo-1.00.tar.gz');
  my $new  = path($filename);

  is($new->slurp, $orig->slurp, 'content of file is the same');

};

subtest 'prefer property' => sub {

  subtest 'default (true)' => sub {

    require Alien::Build;
    my $mock = mock 'Alien::Build::Meta';

    my @calls;

    $mock->around(apply_plugin => sub {
      my($orig, $self, @args) = @_;
      push @calls, \@args if $args[0] eq 'Prefer::SortVersions';
      $orig->($self, @args);
    });

    my $build = alienfile_ok q{
      use alienfile;
      probe sub { 'share' };
      plugin 'Download' => (
        url => 'corpus/dist',
        version => qr/([0-9\.]+)/,
        filter => qr/\.tar\.gz$/,
      );
    };

    is(
      \@calls,
      array {
        item array {
          item 'Prefer::SortVersions';
          item 'filter';
          item T();
          item 'version';
          item T();
        };
        end;
      },
      'loaded Prefer::SortVersions exactly once'
    );

  };

  my $mock = mock 'Alien::Build::Meta';

  $mock->around(apply_plugin => sub {
    my($orig, $self, @args) = @_;
    die 'oopsiedoopsie' if $args[0] eq 'Prefer::SortVersions';
    $orig->($self, @args);
  });

  subtest 'false' => sub {

    my $build = alienfile_ok q{
      use alienfile;
      probe sub { 'share' };
      plugin 'Download' => (
        url => 'corpus/dist',
        version => qr/([0-9\.]+)/,
        filter => qr/\.tar\.gz$/,
        prefer => 0,
      );
    };

    ok 1, "didn't load Prefer::SortVersions";

  };

  subtest 'code reference' => sub {

    undef $mock;

    my $build = alienfile_ok q{
      use alienfile;
      probe sub { 'share' };
      plugin 'Download' => (
        url => 'corpus/dist',
        version => qr/([0-9\.]+)/,
        filter => qr/\.tar\.gz$/,
        prefer => sub {
          my($build, $res) = @_;
          return {
            type => 'list',
            list => [
              sort { $b->{version} <=> $a->{version} } @{ $res->{list} },
            ],
          }
        },
      );
    };

    is(
      $build->prefer(
        { type => 'list', list => [ { filename => 'abc', version => 1 }, { filename => 'def', version => 2 }, { filename => 'ghi', version => 3 } ] },
      ),
      {type => 'list', list => [ { filename => 'ghi', version => 3 }, { filename => 'def', version => 2 }, { filename => 'abc', version => 1 } ] },
    );

  };

};

done_testing;
