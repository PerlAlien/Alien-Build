use 5.008004;
use Test2::V0 -no_srand => 1;
use Test::Alien;
use Test::Alien::Build;
use Alien::Build::Plugin::Build::CMake;
use Path::Tiny ();

eval { require Alien::cmake3 };
skip_all 'test requires Alien::cmake3' if $@;

# To see the actual commands being executed
$ENV{VERBOSE} = 1;

$Alien::Build::Plugin::Fetch::LocalDir::VERSION        ||= '0.99';
$Alien::Build::Plugin::Build::CMake::VERSION           ||= '0.99';
$Alien::Build::Plugin::Gather::IsolateDynamic::VERSION ||= '0.99';

my $xs = do { local $/; <DATA> };

foreach my $type (qw( basic out-of-source ))
{

  subtest $type => sub {

    my $build = alienfile_ok q{
      use alienfile;
      use Path::Tiny qw( path );

      meta->prop->{start_url} = path('corpus/cmake-libpalindrome')->absolute->stringify;

      probe sub { 'share' };

      share {
        plugin 'Fetch::LocalDir';
        plugin 'Extract' => 'd';
        plugin 'Build::CMake';
        plugin 'Gather::IsolateDynamic';

        gather sub {
          my($build) = @_;
          my $prefix = $build->runtime_prop->{prefix};
          $build->runtime_prop->{$_} = "-I$prefix/include" for qw( cflags cflags_static );

          if($build->meta_prop->{platform}->{compiler_type} eq 'microsoft')
          {
            $build->runtime_prop->{$_} = "-LIBPATH:$prefix/lib palindromeStatic.lib" for qw( libs libs_static );
          }
          else
          {
            my $lib = $^O =~ /^(cygwin|MSWin32)$/ ? '-lpalindromeStatic' : '-lpalindrome';
            $build->runtime_prop->{$_} = "-L$prefix/lib $lib" for qw( libs libs_static );
          }
        };
      };
    };

    if($type eq 'out-of-source')
    {
      $build->meta->prop->{out_of_source} = 1;
    }

    if($build->requires('share')->{'Alien::gmake'})
    {
      if(!eval { $build->load_requires($build->install_type); 1 })
      {
        note "prereqs not met";
        return;
      }
    }

    my $alien = alien_build_ok;

    if(! defined $alien)
    {
      if($^O eq 'MSWin32')
      {
        my $tmp = $build->root;
        $tmp =~ s{/}{\\}g;
        $tmp .= "\\..";
        diag "dir $tmp /s";
        diag `dir $tmp /s`;
      }
      else
      {
        my $tmp = Path::Tiny->new($build->root)->parent;
        diag `ls -lR $tmp`;
      }
    }

    alien_ok $alien;

    note 'cflags = ', $alien->cflags;
    note 'libs   = ', $alien->libs;

    xs_ok { xs => $xs, verbose => 1 }, with_subtest {
      my($mod) = @_;
      is($mod->is_palindrome("Something that is not a palindrome"), 0);
      is($mod->is_palindrome("Was it a car or a cat I saw?"), 1);
    };

    run_ok(['palx', 'Something that is not a palindrome'])
      ->note
      ->exit_is(2);

    run_ok(['palx', 'Was it a car or a cat I saw?'])
      ->note
      ->success;

    run_ok(['palx', 'racecar'])
      ->note
      ->success;

  };
};

done_testing

__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <libpalindrome.h>

MODULE = TA_MODULE PACKAGE = TA_MODULE

int
is_palindrome(klass, word)
    const char *klass
    const char *word
  CODE:
    RETVAL = is_palindrome(word);
  OUTPUT:
    RETVAL
