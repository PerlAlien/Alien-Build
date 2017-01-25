use Test2::Bundle::Extended;
use Alien::Build;
use Path::Tiny qw( path );

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

subtest 'compile examples' => sub {

  foreach my $alienfile (path('example')->children(qr/\.alienfile$/))
  {
    my $build = eval {
      Alien::Build->load("$alienfile");
    };
    is $@, '';
    isa_ok $build, 'Alien::Build';
  }

};

done_testing;
