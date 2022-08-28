use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Path::Tiny qw( path );

our $tarball = path('corpus/dist/foo-1.00.tar')->slurp_raw;

alien_subtest 'warn' => sub {

  local $Alien::Build::VERSION = $Alien::Build::VERSION || '2.60';
  local $ENV{ALIEN_DOWNLOAD_RULE} = 'warn';

  require Alien::Build;

  my @warnings;
  my $mock = mock 'Alien::Build' => (
    around => [
      log => sub {
        my($orig, $self, $msg) = @_;
        push @warnings, $msg if $msg =~ /^warning:/;
        $self->$orig($msg);
      },
    ],
  );

  subtest 'no digest, no tls, no problem lol' => sub {

    @warnings = ();

    alienfile_ok q{
      use alienfile;
      probe sub { 'share' };
      share {
        start_url 'http://foo.bar.baz';
        fetch sub {
          return {
            type     => 'file',
            filename => 'foo-1.00.tar',
            content  => $main::tarball,
            version  => '1.00',
            protocol => 'http',
          };
        };
        plugin 'Extract::ArchiveTar' => (format => 'tar');
      };
    };

    alienfile_skip_if_missing_prereqs;
    alien_install_type_is 'share';
    alien_download_ok;
    alien_extract_ok;

    is
      \@warnings,
      bag {
        item match qr/warning: attempting to fetch a non-TLS or bundled URL/;
        item match qr/warning: fetch did not use a secure protocol/;
        item match qr/warning: extracting from a file that was fetched via insecure protocol/;
        etc;
      },
      'expected warnings';

  };

  subtest 'just tls' => sub {

    @warnings = ();

    alienfile_ok q{
      use alienfile;
      probe sub { 'share' };
      share {
        start_url 'https://foo.bar.baz';
        fetch sub {
          return {
            type     => 'file',
            filename => 'foo-1.00.tar',
            content  => $main::tarball,
            version  => '1.00',
            protocol => 'https',
          };
        };
        plugin 'Extract::ArchiveTar' => (format => 'tar');
      };
    };

    alienfile_skip_if_missing_prereqs;
    alien_install_type_is 'share';
    alien_download_ok;
    alien_extract_ok;

    is
      \@warnings,
      array {
        all_items mismatch qr/warning: (attempting to fetch a non-TLS or bundled URL|fetch did not use a secure protocol|extracting from a file that was fetched via insecure protocol)/;
        etc;
      },
      'no unexpected warnings';

  };

  subtest 'tls and digest' => sub {

    @warnings = ();

    alienfile_ok q{
      use alienfile;
      probe sub { 'share' };
      share {
        start_url 'https://foo.bar.baz';
        digest SHA256 => '0478cc6e29f934f87ae457c66a05891aef93179e0674d99fc2e73463b8810817';
        fetch sub {
          return {
            type     => 'file',
            filename => 'foo-1.00.tar',
            content  => $main::tarball,
            version  => '1.00',
            protocol => 'https',
          };
        };
        plugin 'Extract::ArchiveTar' => (format => 'tar');
      };
    };

    alienfile_skip_if_missing_prereqs;
    alien_install_type_is 'share';
    alien_download_ok;
    alien_extract_ok;

    is
      \@warnings,
      array {
        all_items mismatch qr/warning: (attempting to fetch a non-TLS or bundled URL|fetch did not use a secure protocol|extracting from a file that was fetched via insecure protocol)/;
        etc;
      },
      'no unexpected warnings';

  };

  subtest 'just digest' => sub {

    @warnings = ();

    alienfile_ok q{
      use alienfile;
      probe sub { 'share' };
      share {
        start_url 'http://foo.bar.baz';
        digest SHA256 => '0478cc6e29f934f87ae457c66a05891aef93179e0674d99fc2e73463b8810817';
        fetch sub {
          return {
            type     => 'file',
            filename => 'foo-1.00.tar',
            content  => $main::tarball,
            version  => '1.00',
            protocol => 'http',
          };
        };
        plugin 'Extract::ArchiveTar' => (format => 'tar');
      };
    };

    alienfile_skip_if_missing_prereqs;
    alien_install_type_is 'share';
    alien_download_ok;
    alien_extract_ok;

    is
      \@warnings,
      bag {
        item match qr/warning: attempting to fetch a non-TLS or bundled URL/;
        item match qr/warning: fetch did not use a secure protocol/;
        all_items mismatch qr/warning: extracting from a file that was fetched via insecure protocol/;
        etc;
      },
      'expected warnings';

  };

};

alien_subtest 'digest' => sub {
  my $todo = todo 'todo';
  ok 0;
};

alien_subtest 'encrypt' => sub {
  my $todo = todo 'todo';
  ok 0;
};

alien_subtest 'digest_or_encrypt' => sub {
  my $todo = todo 'todo';
  ok 0;
};

alien_subtest 'digest_and_encrypt' => sub {
  my $todo = todo 'todo';
  ok 0;
};

done_testing;