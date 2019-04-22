use Test2::V0 -no_srand => 1;
use Alien::Build::Plugin::Decode::Mojo;
use Test::Alien::Build;
use Path::Tiny qw( path );

subtest 'updates requires' => sub {
  ok 1;
};

foreach my $class (qw( Mojo::DOM Mojo::DOM58 ))
{
  subtest "decode class = $class" => sub {

    my $build = alienfile qq{
      use alienfile;
      plugin 'Decode::Mojo' => ( _class => "$class" );
      probe sub { 'share' };
    };

    alienfile_skip_if_missing_prereqs;

    foreach my $file (path('corpus/dir')->children(qr/\.html$/))
    {
      subtest "parse $file" => sub {
        ok "$file";
      };
    }
  
  };
}

done_testing
