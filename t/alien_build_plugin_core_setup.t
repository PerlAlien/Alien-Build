use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Core::Setup;

subtest 'compiler type' => sub {

  my $build = alienfile_ok q{
    use alienfile;
  };

  ok( $build->meta_prop->{platform}->{compiler_type}, 'has a compiler type' );  
  note "compiler type = @{[ $build->meta_prop->{platform}->{compiler_type} ]}";
};

done_testing;
