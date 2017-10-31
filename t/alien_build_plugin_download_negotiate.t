use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Download::Negotiate;
use Path::Tiny;
use Capture::Tiny qw( capture_merged );
use Alien::Build::Util qw( _dump );
use Test2::Mock;

delete $ENV{$_} for qw( ftp_proxy all_proxy );

subtest 'pick fetch' => sub {

  local %ENV = %ENV;

  subtest 'http' => sub {
  
    my $plugin = Alien::Build::Plugin::Download::Negotiate->new('http://mytest.test/');
    
    is([$plugin->pick], ['Fetch::HTTPTiny','Decode::HTML']);
    is($plugin->scheme, 'http');
  
  };
  
  subtest 'https' => sub {
  
    my $plugin = Alien::Build::Plugin::Download::Negotiate->new('https://mytest.test/');
    
    is([$plugin->pick], ['Fetch::HTTPTiny','Decode::HTML']);
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
    
    is([$plugin->pick], ['Fetch::LWP','Decode::DirListing','Decode::HTML']);
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
  
    skip_all 'subtest requires Devel::Hide' unless eval { require Devel::Hide };

    subtest 'without Net::SSLeay' => sub {
  
      local @INC = @INC;
      note scalar capture_merged { Devel::Hide->import(qw( Net::SSLeay )) };

      my $plugin = Alien::Build::Plugin::Download::Negotiate->new(
        url           => 'https://mytest.test/',
        bootstrap_ssl => 1,
      );
  
      is(
        [$plugin->pick],
        array {
          item ['Fetch::CurlCommand','Fetch::Wget'];
          item 'Decode::HTML';
          end;
        },
      );
    };
    
    subtest 'with Net::SSLeay' => sub {

      local %INC = %INC;    
      $INC{'Net/SSLeay.pm'} = __FILE__;

      my $plugin = Alien::Build::Plugin::Download::Negotiate->new(
        url           => 'https://mytest.test/',
        bootstrap_ssl => 1,
      );
  
      is(
        [$plugin->pick],
        array {
          item 'Fetch::HTTPTiny';
          item 'Decode::HTML';
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
        item 'Decode::HTML';
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

    my $mock = Test2::Mock->new(
      class => 'Alien::Build::Meta',
    );
    
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

  my $mock = Test2::Mock->new(
    class => 'Alien::Build::Meta',
  );

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
