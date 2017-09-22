use Test2::V0 -no_srand => 1;
use Alien::Build::Version::Basic qw( version );

subtest 'basic' => sub {

  subtest 'new' => sub {
    my $version = Alien::Build::Version::Basic->new("1.2.3");
    isa_ok $version, 'Alien::Build::Version::Basic';
    is($version->as_string, '1.2.3');
    is("$version", '1.2.3');
  };
  
  subtest 'version' => sub {
    my $version = version("1.2.3");
    isa_ok $version, 'Alien::Build::Version::Basic';
    is($version->as_string, '1.2.3');
    is("$version", '1.2.3');
  };

  subtest 'bad version' => sub {
    eval { version('a.b.c') };
    like $@, qr/invalud version: a\.b\.c/;
  };

};

subtest 'cmp method' => sub {

  my $version = version('1.2.3');

  ok($version->cmp(version('1.2.2')) >  0);
  ok($version->cmp(version('1.2.3')) == 0);
  ok($version->cmp(version('1.2.4')) <  0);

  ok($version->cmp('1.2.2') >  0);
  ok($version->cmp('1.2.3') == 0);
  ok($version->cmp('1.2.4') <  0);

  eval { $version->cmp('a.b.c') };
  like $@, qr/invalud version: a\.b\.c/;

};

subtest 'cmp operator' => sub {

  my $version = version('1.2.3');

  ok(($version <=> version('1.2.2')) >  0);
  ok(($version <=> version('1.2.3')) == 0);
  ok(($version <=> version('1.2.4')) <  0);

  ok(($version <=> '1.2.2') >  0);
  ok(($version <=> '1.2.3') == 0);
  ok(($version <=> '1.2.4') <  0);

  ok(($version cmp version('1.2.2')) >  0);
  ok(($version cmp version('1.2.3')) == 0);
  ok(($version cmp version('1.2.4')) <  0);

  ok(($version cmp '1.2.2') >  0);
  ok(($version cmp '1.2.3') == 0);
  ok(($version cmp '1.2.4') <  0);

  is($version >  version('1.2.2'), T());
  is($version >  version('1.2.3'), F());
  is($version >= version('1.2.3'), T());
  is($version >= version('1.2.5'), F());
  is($version == version('1.2.3'), T());
  is($version == version('1.2.4'), F());
  is($version != version('1.2.3'), F());
  is($version != version('1.2.4'), T());
  is($version <  version('1.2.4'), T());
  is($version <  version('1.2.3'), F());
  is($version <= version('1.2.3'), T());
  is($version <= version('1.2.2'), F());

  is($version >  '1.2.2', T());
  is($version >  '1.2.3', F());
  is($version >= '1.2.3', T());
  is($version >= '1.2.5', F());
  is($version == '1.2.3', T());
  is($version == '1.2.4', F());
  is($version != '1.2.3', F());
  is($version != '1.2.4', T());
  is($version <  '1.2.4', T());
  is($version <  '1.2.3', F());
  is($version <= '1.2.3', T());
  is($version <= '1.2.2', F());

  eval { my $bool = $version cmp 'a.b.x' };
  like $@, qr/invalud version: a\.b\.x/;

  eval { my $bool = $version <=> 'a.b.y' };
  like $@, qr/invalud version: a\.b\.y/;

  is($version == version('1.2.3.0.0.0'), T());
  is($version == '1.2.3.0.0.0.0', T());
  is(version('1.2.3.0.0.0.0') == $version, T());
  is(($version <=> version('1.2.3.0.0.0')) == 0, T());
  is(($version <=> '1.2.3.0.0.0') == 0, T());
  is((version('1.2.3.0.0.0.0') <=> $version) == 0, T());

};

done_testing;
