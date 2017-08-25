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

  my $intr = Alien::Build::Interpolate::Default->new;
  
  my $val = $intr->interpolate('%{mkdir_deep} foo');
  
  my $expected = $^O eq 'MSWin32' ? 'md foo' : 'mkdir -p foo';
  
  is($val, $expected);
};

done_testing;
