use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Path::Tiny qw( path );
use Alien::Build::Util qw( _dump );

subtest 'basic' => sub {

  local $Alien::Build::VERSION = 2.57;

  my $build = alienfile_ok q{
    use alienfile;
    plugin 'Digest::SHAPP';

    probe sub { 'share' };
  };

  alienfile_skip_if_missing_prereqs;

  foreach my $type (qw( path content ))
  {

    my $good = 'a7e79996a02d3dfc47f6f3ec043c67690dc06a10d091bf1d760fee7c8161391a';
    my $bad  = '032772271db8f134e4914bca0e933361e1946c91c21e43610d301d39cbdb9d52';

    subtest "file stored as $type" => sub {
      my $file = {
        type     => 'file',
        filename => 'foo.txt.gz',
        path     => path("corpus/alien_build_plugin_digest_shapp/foo.txt.gz")->absolute->stringify,
        tmp      => 0,
      };

      if($type eq 'content')
      {
        $file->{content} = path(delete $file->{path})->slurp_raw;
        delete $file->{tmp};
      }

      note _dump($file);

      is
        $build->meta->call_hook( check_digest => $build, $file, 'xxx', $good ),
        0,
        'plugin returns 0 if it does not recognize the algorthim (xxx)';

      is
        $build->meta->call_hook( check_digest => $build, $file, 'SHA13', $good ),
        0,
        'plugin returns 0 if it does not recognize the algorthim (SHA13)';

      is
        $build->meta->call_hook( check_digest => $build, $file, 'SHA256', $good ),
        1,
        'plugin returns 1 for valid signature';

      is
        dies { $build->meta->call_hook( check_digest => $build, $file, 'SHA256', $bad ) },
        match qr/^foo.txt.gz SHA256 digest does not match: got $good, expected $bad/,
        'plugin dies on invalid signature';
    }
  }

};

done_testing;
