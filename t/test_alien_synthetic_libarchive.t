use strict;
use warnings;
use Test2::Require::Module 'Alien::Libarchive' => '0.26';
use Test2::Bundle::Extended;
use Test::Alien;

plan 6;

is(
  intercept { alien_ok 'Alien::Libarchive' },
  array {
    event Ok => sub {
      call pass => F();
      call name => 'Alien::Libarchive responds to: cflags libs dynamic_libs bin_dir';
    },
  },
  'Alien::Libarchive fails alien_ok'
);

my $real = Alien::Libarchive->new;
my @dlls = eval { $real->dlls };
my $alien = synthetic {
  cflags       => scalar $real->cflags,
  libs         => scalar $real->libs,
  # wrap in an eval as Alien::Libarchive::Installer
  # still uses FFI::Raw for probing and will crap out if
  # it isn't installed.
  dynamic_libs => [@dlls],
};

alien_ok $alien;

xs_ok do { local $/; <DATA> }, with_subtest {
  my($module) = @_;
  plan 1;
  my $ptr = $module->archive_read_new;
  like $ptr, qr{^[0-9]+$};
  $module->archive_read_free($ptr);
};

SKIP: {

  skip "Test (may) require FFI::Raw", 2 unless @dlls;


ffi_ok { symbols => [qw( archive_read_new )] }, with_subtest {
  my($ffi) = @_;
  my $new  = $ffi->function(archive_read_new => [] => 'opaque');
  my $free = $ffi->function(archive_read_close => ['opaque'] => 'void');
  my $ptr = $new->();
  like $ptr, qr{^[0-9]+$};
  $free->($ptr);  
};

}

__DATA__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <archive.h>

MODULE = TA_MODULE PACKAGE = TA_MODULE

void *archive_read_new(class);
    const char *class;
  CODE:
    RETVAL = (void*) archive_read_new();
  OUTPUT:
    RETVAL

void archive_read_free(class, ptr);
    const char *class;
    void *ptr;
  CODE:
    archive_read_free(ptr);
