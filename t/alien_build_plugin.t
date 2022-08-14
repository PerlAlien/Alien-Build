use 5.008004;
use Test2::V0 -no_srand => 1;
use Alien::Build::Plugin ();
use lib 'corpus/lib';

subtest 'basic' => sub {

  my $plugin = Alien::Build::Plugin->new;
  isa_ok $plugin, 'Alien::Build::Plugin';

};

subtest 'properties' => sub {

  require Alien::Build::Plugin::RogerRamjet;

  subtest 'defaults' => sub {

    my $plugin = Alien::Build::Plugin::RogerRamjet->new;
    is $plugin->foo, 22;
    is $plugin->bar, 'something generated';

  };

  subtest 'override' => sub {

    my $plugin = Alien::Build::Plugin::RogerRamjet->new(
      foo => 42,
      bar => 'anything else',
    );

    is $plugin->foo, 42;
    is $plugin->bar, 'anything else';

  };

  subtest 'set' => sub {

    my $plugin = Alien::Build::Plugin::RogerRamjet->new;

    $plugin->foo(92);
    $plugin->bar('string');

    is $plugin->foo, 92;
    is $plugin->bar, 'string';

  };

};

subtest 'instance-id' => sub {

  {
    package
      Alien::Build::Plugin::ABC::XYZ1;
    use Alien::Build::Plugin;

    has foo => undef;
    has bar => undef;
  }

  {
    package
      Alien::Build::Plugin::ABC::XYZ2;
    use Alien::Build::Plugin;

    has foo => undef;
  }

  is(
    Alien::Build::Plugin::ABC::XYZ1->new->instance_id,
    match qr/^[a-z0-9]{40}$/,
    'id is a 40 character hex value',
  );

  is(
    Alien::Build::Plugin::ABC::XYZ1->new->instance_id,
    Alien::Build::Plugin::ABC::XYZ1->new->instance_id,
    'zero args is the consistent',
  );

  isnt(
    Alien::Build::Plugin::ABC::XYZ1->new->instance_id,
    Alien::Build::Plugin::ABC::XYZ2->new->instance_id,
    'zero args different class is different',
  );

  isnt(
    Alien::Build::Plugin::ABC::XYZ1->new(foo => 1)->instance_id,
    Alien::Build::Plugin::ABC::XYZ2->new(foo => 1)->instance_id,
    'same args different class is different',
  );

  isnt(
    Alien::Build::Plugin::ABC::XYZ1->new( foo => 1, bar => 2)->instance_id,
    Alien::Build::Plugin::ABC::XYZ1->new->instance_id,
    'args vs no args different',
  );

  isnt(
    Alien::Build::Plugin::ABC::XYZ1->new( foo => 1, bar => 2)->instance_id,
    Alien::Build::Plugin::ABC::XYZ1->new( foo => 2, bar => 3)->instance_id,
    'args vs different args different',
  );

  is(
    Alien::Build::Plugin::ABC::XYZ1->new( foo => 1, bar => 2)->instance_id,
    Alien::Build::Plugin::ABC::XYZ1->new( bar => 2, foo => 1)->instance_id,
    'same args is same',
  );

  is(
    Alien::Build::Plugin::ABC::XYZ1->new( foo => [1,2,3], bar => 2)->instance_id,
    Alien::Build::Plugin::ABC::XYZ1->new( bar => 2, foo => [1,2,3])->instance_id,
    'same args is same (array)',
  );

  isnt(
    Alien::Build::Plugin::ABC::XYZ1->new( foo => [1,3,2], bar => 2)->instance_id,
    Alien::Build::Plugin::ABC::XYZ1->new( bar => 2, foo => [1,2,3])->instance_id,
    'different args is same (array)',
  );

};

done_testing;

