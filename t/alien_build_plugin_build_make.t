use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Build::Make;

subtest 'compile' => sub {
  foreach my $type (qw( nmake dmake gmake umake ))
  {
    subtest $type => sub {
      alienfile_ok qq{
        use alienfile;
        plugin 'Build::Make' => '$type';
      };
    };
  }
};

done_testing
