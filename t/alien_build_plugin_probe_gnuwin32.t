use Test2::V0;
use Alien::Build::Plugin::Probe::GnuWin32;
use Capture::Tiny qw( capture_merged );

subtest 'error no regex' => sub {

  my $plugin = eval { Alien::Build::Plugin::Probe::GnuWin32->new };
  my $error =  $@;
  isnt $error, '', 'throws exception with nothing';
  note "error = $error";

};

subtest 'using the typo' => sub {

  note scalar capture_merged { eval { Alien::Build::Plugin::Probe::GnuWin32->new( registery_key_regex => qr/ foo / ) } };
  is $@, '', 'no error';

};

subtest 'using the correctly spelled one' => sub {

  my $plugin = eval { Alien::Build::Plugin::Probe::GnuWin32->new( registry_key_regex => qr/ foo / )  };
  is $@, '', 'no error';

};

done_testing;
