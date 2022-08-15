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

    subtest "file stored as $type" => sub {
      my $file = {
        type     => 'file',
        filename => 'foo.txt',
        path     => path("corpus/alien_build_plugin_digest_shapp/foo.txt")->absolute->stringify,
        tmp      => 0,
      };

      if($type eq 'content')
      {
        $file->{content} = path(delete $file->{path})->slurp_raw;
        delete $file->{tmp};
      }

      note _dump($file);

      is
        $build->meta->call_hook( check_digest => $build, $file, 13, '032772271db8f134e4914bca0e933361e1946c91c21e43610d301d39cbdb9d51' ),
        0,
        'plugin returns 0 if it does not recognize the algorthim';

      is
        $build->meta->call_hook( check_digest => $build, $file, 'SHA256', '032772271db8f134e4914bca0e933361e1946c91c21e43610d301d39cbdb9d51' ),
        1,
        'plugin returns 1 for valid signature';

      is
        dies { $build->meta->call_hook( check_digest => $build, $file, 'SHA256', '032772271db8f134e4914bca0e933361e1946c91c21e43610d301d39cbdb9d52' ) },
        match qr/^foo.txt SHA256 digest does not match: got 032772271db8f134e4914bca0e933361e1946c91c21e43610d301d39cbdb9d51, expected 032772271db8f134e4914bca0e933361e1946c91c21e43610d301d39cbdb9d52/,
        'plugin dies on invalid signature';
    }
  }

};

done_testing;
