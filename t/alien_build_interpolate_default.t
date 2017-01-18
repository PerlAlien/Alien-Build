use Test2::Bundle::Extended;
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

done_testing;
