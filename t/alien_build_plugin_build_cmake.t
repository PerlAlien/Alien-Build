use Test2::Require::Module 'Alien::cmake3';
use Test2::V0 -no_srand => 1;
use Test::Alien;
use Test::Alien::Build;
use Alien::Build::Plugin::Build::CMake;
use Path::Tiny ();

subtest 'basic' => sub {

  my $buil = alienfile_ok q{
    use alienfile;
    use Path::Tiny qw( path );
  
    meta->prop->{start_url} = path('corpus/libpalindrome')->absolute->stringify;

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
          my $lib    = $^O eq 'MSWin32' ? '-lpalindromeStatic' : '-lpalindrome';
          $build->runtime_prop->{$_} = "-L$prefix/lib $lib" for qw( libs libs_static );
        }
      };
    };
  };

  my $alien = alien_build_ok;
  
  alien_ok $alien;
  
  xs_ok { xs => do { local $/; <DATA> }, verbose => 1 }, with_subtest {
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
