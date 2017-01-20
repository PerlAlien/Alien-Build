use Test2::Bundle::Extended;
use lib 't/lib';
use MyTest::System;
use Alien::Build::CommandSequence;
use MyTest;
use Capture::Tiny qw( capture_merged );

subtest 'basic' => sub {

  my $seq = Alien::Build::CommandSequence->new;
  isa_ok $seq, 'Alien::Build::CommandSequence';

};

subtest 'apply requirements' => sub {

  my($build, $meta) = build_blank_alien_build;
  
  my $intr = $meta->interpolator;
  
  $intr->add_helper(foo => undef, Foo => '1.00');
  $intr->add_helper(bar => undef, Bar => '2.00');
  $intr->add_helper(baz => undef, Baz => '3.00');
  
  my $seq = Alien::Build::CommandSequence->new(
    '%{foo}',
    [ '%{bar}' ],
    [ '%{baz}', '--version', sub {} ],
    sub {},
  );
  
  $seq->apply_requirements($meta, 'share');
  
  is(
    $build->requires('share'),
    hash {
      field Foo => '1.00';
      field Bar => '2.00';
      field Baz => '3.00';
    },
  );
  
};

subtest 'execute' => sub {

  my($build, $meta) = build_blank_alien_build;
  my $intr = $meta->interpolator;
  $intr->add_helper(foo => sub { 'myfoo' });

  system_clear;
  
  note capture_merged {
    Alien::Build::CommandSequence->new(
      '%{foo}',
      [ 'stuff', '%{foo}' ],
    )->execute($build);
  };
  
  is(
    system_last,
    [ ['myfoo'], ['stuff','myfoo'] ],
    'plain',
  );
  
  system_clear;
  
  my $error;
  note capture_merged {
    eval {
      Alien::Build::CommandSequence->new(
        'bogus',
        [ 'stuff', '%{foo}' ],
      )->execute($build);
    };
    $error = $@;
  };
  
  like $error, qr/command failed/;
  
  system_clear;
  
  system_hook stuff => sub {
    print "stuff output";
    print STDERR "stuff error";
  };
  
  my @cap;
  
  note capture_merged {
    Alien::Build::CommandSequence->new(
      [ 'stuff', '%{foo}', sub { @cap = @_ } ],
    )->execute($build);
  };
  
  is(
    \@cap,
    array {
      item object {
        prop blessed => ref $build;
        call sub { shift->isa('Alien::Build') } => T();
      };
      item hash {
        field command => ['stuff','myfoo'];
        field err  => match qr/stuff error/;
        field out  => match qr/stuff output/;
        field exit => 0;
      };
    },
  );
  
  system_hook bogus => sub {
    print "bogus output";
    print STDERR "bogus error";
  };
  
  @cap = ();
  
  note capture_merged {
    Alien::Build::CommandSequence->new(
      [ 'bogus', '%{foo}', sub { @cap = @_ } ],
    )->execute($build);
  };

  is(
    \@cap,
    array {
      item object {
        prop blessed => ref $build;
        call sub { shift->isa('Alien::Build') } => T();
      };
      item hash {
        field command => ['bogus','myfoo'];
        field err  => match qr/bogus error/;
        field out  => match qr/bogus output/;
        field exit => -1;
      };
    },
  );
};

done_testing;
