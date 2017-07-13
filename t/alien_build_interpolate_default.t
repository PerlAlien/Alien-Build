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

done_testing;
