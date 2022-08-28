use 5.008004;
use Test2::V0 -no_srand => 1;
use Test::Alien::Build;

subtest 'preload code ref' => sub {

  my $meta1;
  my $meta2;

  no warnings 'once';

  local @Alien::Build::rc::PRELOAD = (sub {
    ($meta1) = @_;
  });

  local @Alien::Build::rc::POSTLOAD = (sub {
    ($meta2) = @_;
  });

  my $build = alienfile_ok q{
    use alienfile;
  };

  isa_ok $meta1, 'Alien::Build::Meta';
  isa_ok $meta2, 'Alien::Build::Meta';

};

done_testing;
