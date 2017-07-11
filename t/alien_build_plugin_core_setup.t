use Test2::V0;
use Test::Alien::Build;
use Alien::Build::Plugin::Core::Setup;
use lib 't/lib';
use MyTest;

subtest 'compiler type' => sub {

  my $build = alienfile q{
    use alienfile;
  };

  ok( $build->meta_prop->{platform}->{compiler_type}, 'has a compiler type' );  
  note "compiler type = @{[ $build->meta_prop->{platform}->{compiler_type} ]}";
};

done_testing;
