use 5.008004;
use Test2::V0 -no_srand => 1;
use Alien::Build::Interpolate::Default;
use lib 'corpus/lib';

subtest 'basic usage' => sub {

  my $intr = Alien::Build::Interpolate::Default->new;
  isa_ok $intr, 'Alien::Build::Interpolate';

  if(eval { require YAML })
  {
    note YAML::Dump($intr);
  }
  else
  {
    require Data::Dumper;
    note Data::Dumper::Dumper($intr);
  }

};

subtest 'cwd' => sub {

  my $intr = Alien::Build::Interpolate::Default->new;

  my $val = $intr->interpolate('%{cwd}');

  ok $val, "%{cwd} is okay";
  note "val = $val";

};

subtest 'mkdir_deep' => sub {

  local $Alien::Build::VERSION = '1.04';

  my $intr = Alien::Build::Interpolate::Default->new;

  my $val = $intr->interpolate('%{mkdir_deep} foo');

  my $expected = $^O eq 'MSWin32' ? 'md foo' : 'mkdir -p foo';

  is($val, $expected);
};

subtest 'make_path' => sub {

  local $Alien::Build::VERSION = '1.05';

  my $intr = Alien::Build::Interpolate::Default->new;

  my $val = $intr->interpolate('%{make_path} foo');

  my $expected = $^O eq 'MSWin32' ? 'md foo' : 'mkdir -p foo';

  is($val, $expected);
};

subtest dynamic => sub {

  my %which;

  my $mock = mock 'Alien::Build::Interpolate::Default' => (
    override => [
      which => sub { my $command = shift; $which{$command} },
    ],
  );

  subtest 'have bison' => sub {

    $which{bison} = '/usr/bin/bison';

    my $intr = Alien::Build::Interpolate::Default->new;

    is
      [$intr->requires('%{bison}')],
      []
    ;

    is
      $intr->interpolate('-%{bison}-'),
      '-bison-',
    ;

  };

  subtest 'no bison' => sub {

    delete $which{bison};

    my $intr = Alien::Build::Interpolate::Default->new;

    is
      [$intr->requires('%{bison}')],
      [ 'Alien::bison' => '0.17' ]
    ;

  };

};

done_testing;
