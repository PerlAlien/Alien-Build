use lib 't/lib';
use MyTest::FauxFetchCommand;
use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Fetch::Wget;
use Path::Tiny qw( path );

subtest 'fetch from http' => sub {

  my $config = test_config 'httpd';
  
  skip_all 'Test requires httpd config' unless $config;
  
  my $base = $config->{url};

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

done_testing;
