use Test2::V0 -no_srand => 1;
use Alien::Build;
use Alien::Build::Log;

subtest constructors => sub {

  subtest 'basic' => sub {

    eval { Alien::Build::Log->new };
    like $@, qr/Cannot instantiate base class/;

    my $log = Alien::Build::Log->default;
    isa_ok $log, 'Alien::Build::Log';
    isa_ok $log, 'Alien::Build::Log::Default';

    undef $log;

    Alien::Build::Log->set_log_class('Alien::Build::Log::Bogus');
    eval { Alien::Build::Log->default };
    like $@, qr/Can't locate Alien\/Build\/Log\/Bogus\.pm/;
  };

  subtest 'override with set_log_class' => sub {

    our $roger;

    { package
        Alien::Build::Log::Roger;
      use base qw( Alien::Build::Log );
      sub log {
        my (undef, %opt) = @_;
        $main::roger = \%opt;
      }
    }

    Alien::Build::Log->set_log_class('Alien::Build::Log::Roger');

    isa_ok(Alien::Build::Log->default, 'Alien::Build::Log');
    isa_ok(Alien::Build::Log->default, 'Alien::Build::Log::Roger');

    Alien::Build->log("hello");  my $line = __LINE__;

    is(
      $roger,
      hash {
        field caller => array {
          item 'main';
          item __FILE__;
          item $line;
        };
        field message => 'hello';
        end;
      },
      'message sent to log method'
    );

  };

  subtest 'override with environment' => sub {

    our $dodger;

    { package
        Alien::Build::Log::Dodger;
      use base qw( Alien::Build::Log );
      sub log {
        my (undef, %opt) = @_;
        $main::dodger = \%opt;
      }
    }

    Alien::Build::Log->set_log_class(undef);
    $ENV{ALIEN_BUILD_LOG} = 'Alien::Build::Log::Dodger';

    isa_ok(Alien::Build::Log->default, 'Alien::Build::Log');
    isa_ok(Alien::Build::Log->default, 'Alien::Build::Log::Dodger');

    Alien::Build->log("hello");  my $line = __LINE__;

    is(
      $dodger,
      hash {
        field caller => array {
          item 'main';
          item __FILE__;
          item $line;
        };
        field message => 'hello';
        end;
      },
      'message sent to log method'
    );

  };

};

done_testing;
