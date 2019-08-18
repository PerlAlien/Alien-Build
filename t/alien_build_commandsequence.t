use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Capture::Tiny qw( capture_merged );

{
  my %commands;
  my @command_list;

  BEGIN {

    *CORE::GLOBAL::system = sub {
      push @command_list, [@_];
      if($commands{$_[0]})
      {
        $commands{$_[0]}->(@_);
      }
      $? = $_[0] eq 'bogus' ? -1 : 0;
    };
  }

  sub system_last
  {
    \@command_list;
  }

  sub system_clear
  {
    @command_list = ();
  }

  sub system_hook
  {
    my($name, $code) = @_;
    $commands{$name} = $code;
  }
}

use Alien::Build::CommandSequence;

subtest 'basic' => sub {

  my $seq = Alien::Build::CommandSequence->new;
  isa_ok $seq, 'Alien::Build::CommandSequence';

};

subtest 'apply requirements' => sub {

  my $build = alienfile filename => 'corpus/blank/alienfile';
  my $meta = $build->meta;

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

  my $build = alienfile filename => 'corpus/blank/alienfile';
  my $meta = $build->meta;
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

  system_hook stuff2 => sub {
    print "single line\n";
    print STDERR "stuff error\n";
    print STDERR "stuff error\n";
  };

  system_clear;

  note capture_merged {
    Alien::Build::CommandSequence->new(
      [ 'stuff2', '%{foo}', \'%{alien.runtime.foo}' ],
    )->execute($build);
  };

  is($build->runtime_prop->{foo}, 'single line');

  system_clear;

  system_hook 'stuff2 myfoo' => sub {
    print "single line2\n";
    print STDERR "stuff error\n";
    print STDERR "stuff error\n";
  };

  note capture_merged {
    Alien::Build::CommandSequence->new(
      [ 'stuff2 %{foo}', \'%{alien.runtime.foo2}' ],
    )->execute($build);
  };

  is($build->runtime_prop->{foo2}, 'single line2');
  is system_last, [['stuff2 myfoo']];

  system_clear;

  system_hook 'stuff2 myfoo' => sub {
    print "single line2\n";
    print STDERR "stuff error\n";
    print STDERR "stuff error\n";
  };

  note capture_merged {
    Alien::Build::CommandSequence->new(
      [ 'stuff2 %{foo}', \'%{.runtime.foo2}' ],
    )->execute($build);
  };

  is($build->runtime_prop->{foo2}, 'single line2');
  is system_last, [['stuff2 myfoo']];

};

done_testing;
