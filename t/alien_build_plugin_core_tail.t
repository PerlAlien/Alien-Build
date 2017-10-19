use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Core::Tail;

subtest 'out-of-source build' => sub {

  my $build = alienfile_ok q{
    use alienfile;
    meta->prop->{out_of_source} = 1;
  };

  is(
    $build->requires('configure'),
    hash {
      field 'Alien::Build' => '1.08';
      etc;
    },
  );


};

done_testing;
