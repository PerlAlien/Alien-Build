use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Fetch::CurlCommand;
use Path::Tiny qw( path );
use Capture::Tiny ();
use JSON::PP ();

sub capture_note (&)
{
  my($code) = @_;
  my($out, $error, @ret) = Capture::Tiny::capture_merged(sub { my @ret = eval { $code->() }; ($@, @ret) });
  note $out;
  die $error if $error;
  wantarray ? @ret : $ret[0];
}

sub test_config
{
  my($name) = @_;
  my $path = path("t/bin/$name.json");
  return JSON::PP::decode_json(scalar $path->slurp) if -f $path;
}

subtest 'fetch from https' => sub {

  my $config = test_config 'httpd';
  
  skip_all 'Test requires httpd config' unless $config;
  
  my $base = $config->{url};
  $base =~ s{dist/$}{alien_build_plugin_fetch_curlcommand};
  note "base = $base";

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
        field type    => 'html';
        field base    => "$base/html_test.html";
        field content => "<html><head><title>Hello World</title></head><body><p>Hello World</p></body></html>\n";
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
  
};

done_testing
