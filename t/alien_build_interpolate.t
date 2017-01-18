use Test2::Bundle::Extended;
use Alien::Build::Interpolate;
use lib 'corpus/lib';

subtest 'basic usage' => sub {

  my $intr = Alien::Build::Interpolate->new;
  isa_ok $intr, 'Alien::Build::Interpolate';

  $intr->add( foo => '"foo" . "foo"' );
  
  is( $intr->interpolate("bar%{foo}baz"), 'barfoofoobaz' );  
  is( $intr->interpolate("bar%%baz"), 'bar%baz' );
  
  $intr->add( foo1 => sub { 'foo1' . 'foo1' } );

  is( $intr->interpolate("bar%{foo1}baz"), 'barfoo1foo1baz' );  

  $intr->add( 'foomake1', undef, 'Alien::foomake' => '0.22' );
  $intr->add( 'foomake2', undef, 'Alien::foomake' => '0.24' );
  $intr->add( 'foomake3', undef, 'Alien::foomake' => '0.29' );
  $intr->add( 'foomake4', undef, 'Alien::foobogus' => '0'   );
  
  is( $intr->interpolate("-%{foomake1}-"), '-foomake.exe-' );
  is( $intr->interpolate("-%{foomake2}-"), '-foomake.exe-' );

  eval { $intr->interpolate("-%{foomake3}-") };
  isnt( $@, '', "error = $@");

  eval { $intr->interpolate("-%{foomake4}-") };
  isnt( $@, '', "error = $@");

};

done_testing;
