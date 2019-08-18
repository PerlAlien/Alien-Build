use Test2::V0 -no_srand => 1;
use Alien::Build::Interpolate;
use lib 'corpus/lib';

subtest 'basic usage' => sub {

  my $intr = Alien::Build::Interpolate->new;
  isa_ok $intr, 'Alien::Build::Interpolate';

  $intr->add_helper( foo => '"foo" . "foo"' );

  is( $intr->interpolate("bar%{foo}baz"), 'barfoofoobaz' );
  is( $intr->interpolate("bar%%baz"), 'bar%baz' );

  $intr->add_helper( foo1 => sub { 'foo1' . 'foo1' } );

  is( $intr->interpolate("bar%{foo1}baz"), 'barfoo1foo1baz' );

  $intr->add_helper( 'foomake1', undef, 'Alien::foomake' => '0.22' );
  $intr->add_helper( 'foomake2', undef, 'Alien::foomake' => '0.24' );
  $intr->add_helper( 'foomake3', undef, 'Alien::foomake' => '0.29' );
  $intr->add_helper( 'foomake4', undef, 'Alien::foobogus' => '0'   );

  is( $intr->interpolate("-%{foomake1}-"), '-foomake.exe-' );
  is( $intr->interpolate("-%{foomake2}-"), '-foomake.exe-' );

  eval { $intr->interpolate("-%{foomake3}-") };
  isnt( $@, '', "error!");
  note $@;

  eval { $intr->interpolate("-%{foomake4}-") };
  isnt( $@, '', "error!");
  note $@;

  $intr->add_helper( bar => undef, 'XYZ::ABC' => '1.234' );
  $intr->add_helper( baz => undef, 'ABC::XYZ' => '4.321' );

  is( [$intr->requires("%{bar}%{baz}")], [ 'XYZ::ABC' => '1.234', 'ABC::XYZ' => '4.321' ], 'requires' );

  eval { $intr->add_helper( foo1 => sub { } ) };
  like $@, qr{duplicate implementation for interpolated key foo1};

  $intr->replace_helper( foo1 => sub { 'newfoo1' } );
  is( $intr->interpolate("%{foo1}"), 'newfoo1' );

  eval { $intr->interpolate('%{totallybogus}') };
  my $error = $@;
  like $error, qr/no helper defined for totallybogus/;

};

subtest 'clone' => sub {

  my $intr1 = Alien::Build::Interpolate->new;
  isa_ok $intr1, 'Alien::Build::Interpolate';

  $intr1->add_helper( foo => sub { 100 } );

  my $intr2 = $intr1->clone;

  $intr2->add_helper( bar => sub { 200 } );

  is( $intr1->interpolate('%{foo}'), 100);
  is( $intr2->interpolate('%{foo}'), 100);
  is( $intr2->interpolate('%{bar}'), 200);

  my $ret = eval { $intr1->interpolate('%{bar}') };
  my $error = $@;
  like $error, qr/no helper defined for bar/;
};

subtest 'property' => sub {

  my $intr = Alien::Build::Interpolate->new;
  isa_ok $intr, 'Alien::Build::Interpolate';

  is(
    $intr->interpolate("%{foo.bar}", { foo => { bar => 'baz' } }),
    'baz',
  );

  eval {
    $intr->interpolate("'%{foo.bar}'", { foo => { bar1 => 'baz' } }),
  };

  like $@, qr/No property foo.bar is defined/;

  is(
    $intr->interpolate("%{foo.bar.baz}", { foo => { bar => { baz => 'starscream' } } }),
    'starscream',
  );

};

subtest 'property, default to alien' => sub {

  my $intr = Alien::Build::Interpolate->new;
  isa_ok $intr, 'Alien::Build::Interpolate';

  is(
    $intr->interpolate('%{.foo.bar}', { alien => { foo => { bar => 'baz' } } }),
    'baz',
  );

};

subtest 'has_helper' => sub {

  my $intr = Alien::Build::Interpolate->new;

  $intr->add_helper(foo => sub { 'foo' . (1+2) });
  $intr->add_helper(bar => '"bar" . (3+4)');

  my $foo = $intr->has_helper('foo');
  my $bar = $intr->has_helper('bar');

  is(ref($foo), 'CODE');
  is(ref($bar), 'CODE');

  is($foo->(), 'foo3');
  is($bar->(), 'bar7');

};

done_testing;
