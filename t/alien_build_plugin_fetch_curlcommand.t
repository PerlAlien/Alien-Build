use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Fetch::CurlCommand;
use Capture::Tiny ();

sub capture_note (&)
{
  my($code) = @_;
  my($out, $error, @ret) = Capture::Tiny::capture_merged(sub { my @ret = eval { $code->() }; ($@, @ret) });
  note $out;
  die $error if $error;
  wantarray ? @ret : $ret[0];
}

subtest 'fetch from https' => sub {

  my $build = alienfile_ok q{
    use alienfile;
    
    meta->prop->{start_url} = 'https://ftp.gnu.org/gnu/autoconf';
    
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
        field base    => T();
        field content => T();
        end;
      },
    );

  };
  
};

done_testing
