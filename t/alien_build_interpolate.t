use 5.008004;
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

  is
    [$intr->requires('%{totallybogus}')],
    [],
  ;

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

subtest 'requirement callback' => sub {

  my $intr = Alien::Build::Interpolate->new;

  $intr->add_helper( foo1 => undef, sub { return ( 'Alien::libfoo' => '1' ) } );

  is( [$intr->requires("%{foo1}")], [ 'Alien::libfoo' => '1' ], 'requires' );

  $intr->add_helper( foo2 => undef, sub {
    my $helper = shift;
    $helper->code(sub { 'foo2' });
    return ();
  });

  is( [$intr->requires("%{foo2}")], [], 'requires' );
  is( $intr->interpolate('-%{foo2}-'), '-foo2-' );

};

subtest 'property' => sub {

  require Alien::Build;

  my $build = Alien::Build->new;
  $build->install_prop->{foo}->{bar} = 'baz';

  is
    $build->meta->interpolator->interpolate('%{.install.foo.bar}', $build),
    'baz',
    'able to fetch .install.foo.bar using meta->interpolator->interpolate';

  is
    $build->meta->interpolator->interpolate('%{alien.install.foo.bar}', $build),
    'baz',
    'able to fetch alien.install.foo.bar using meta->interpolator->interpolate';

  is
    dies { $build->meta->interpolator->interpolate('%{.install.foo.bar1}', $build) },
    match qr/^No property \.install\.foo\.bar1/,
    'unable to interpolate invalid property';

};

done_testing;
