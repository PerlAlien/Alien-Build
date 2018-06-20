use Test2::V0 -no_srand => 1;
use Test::Alien;
use Alien::Base;
use lib 'corpus/alt/lib';
use Alien::libfoo2;

subtest 'test a share install' => sub {

  alien_ok 'Alien::libfoo2';

  subtest 'default' => sub {
    like( Alien::libfoo2->cflags,        qr{-I.*Alien-libfoo2/include -DFOO=1} );
    like( Alien::libfoo2->libs,          qr{-L.*Alien-libfoo2/lib -lfoo} );
    like( Alien::libfoo2->cflags_static, qr{-I.*Alien-libfoo2/include -DFOO=1 -DFOO_STATIC=1} );
    like( Alien::libfoo2->libs_static,   qr{-L.*Alien-libfoo2/lib -lfoo -lbar -lbaz} );
    is( Alien::libfoo2->version,         '2.3.4' );
    is( Alien::libfoo2->runtime_prop->{arbitrary}, 'two');
  };
  
  subtest 'foo1' => sub {
  
    my $alien = Alien::libfoo2->alt('foo1');
    
    isa_ok $alien, 'Alien::Base';
    isa_ok $alien, 'Alien::libfoo2';

    like( $alien->cflags,        qr{-I.*Alien-libfoo2/include -DFOO=1} );
    like( $alien->libs,          qr{-L.*Alien-libfoo2/lib -lfoo} );
    like( $alien->cflags_static, qr{-I.*Alien-libfoo2/include -DFOO=1 -DFOO_STATIC=1} );
    like( $alien->libs_static,   qr{-L.*Alien-libfoo2/lib -lfoo -lbar -lbaz} );
    is( $alien->version,         '2.3.4' );
    is( $alien->runtime_prop->{arbitrary}, 'two');
  
  };
  
  subtest 'foo2' => sub {

    my $alien = Alien::libfoo2->alt('foo2');
    
    isa_ok $alien, 'Alien::Base';
    isa_ok $alien, 'Alien::libfoo2';

    like( $alien->cflags,        qr{-I.*Alien-libfoo2/include -DFOO=2} );
    like( $alien->libs,          qr{-L.*Alien-libfoo2/lib -lfoo1} );
    like( $alien->cflags_static, qr{-I.*Alien-libfoo2/include -DFOO=2 -DFOO_STATIC=2} );
    like( $alien->libs_static,   qr{-L.*Alien-libfoo2/lib -lfoo1 -lbar -lbaz} );
    is( $alien->version,         '2.3.5' );
    is( $alien->runtime_prop->{arbitrary}, 'four');

  };
  
  subtest 'foo3' => sub {
  
    my $alien = Alien::libfoo2->alt('foo3');
    
    isa_ok $alien, 'Alien::Base';
    isa_ok $alien, 'Alien::libfoo2';

    like( $alien->cflags,        qr{-I.*Alien-libfoo2/include -DFOO=1} );
    like( $alien->libs,          qr{-L.*Alien-libfoo2/lib -lfoo} );
    like( $alien->cflags_static, qr{-I.*Alien-libfoo2/include -DFOO=1 -DFOO_STATIC=1} );
    like( $alien->libs_static,   qr{-L.*Alien-libfoo2/lib -lfoo -lbar -lbaz} );
    is( $alien->version,         '2.3.4' );
    is( $alien->runtime_prop->{arbitrary}, 'five');
  
  };
  
  subtest 'foo4' => sub {
  
    eval { Alien::libfoo2->alt('foo4') };
    like $@, qr/no such alt: foo4/;
  
  };
  
  subtest 'default -> foo2 -> foo1' => sub {
  
    my $alien = Alien::libfoo2->alt('foo2')->alt('foo1');
  
    isa_ok $alien, 'Alien::Base';
    isa_ok $alien, 'Alien::libfoo2';

    like( $alien->cflags,        qr{-I.*Alien-libfoo2/include -DFOO=1} );
    like( $alien->libs,          qr{-L.*Alien-libfoo2/lib -lfoo} );
    like( $alien->cflags_static, qr{-I.*Alien-libfoo2/include -DFOO=1 -DFOO_STATIC=1} );
    like( $alien->libs_static,   qr{-L.*Alien-libfoo2/lib -lfoo -lbar -lbaz} );
    is( $alien->version,         '2.3.4' );
    is( $alien->runtime_prop->{arbitrary}, 'two');

  };
  
};

done_testing
