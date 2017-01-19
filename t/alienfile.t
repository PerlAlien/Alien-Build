use Test2::Bundle::Extended;
use Alien::Build;

subtest 'non struct alienfile' => sub {

  eval {
    Alien::Build->load('corpus/nonstrict/alienfile');
  };
  my $error = $@;
  isnt $error, '', 'throws error';
  note "error = $error"; 

};

subtest 'warnings alienfile' => sub {

  my $warning = warning { Alien::Build->load('corpus/warning/alienfile') };
  
  ok $warning;
  note $warning;

};

done_testing;
