package MyTest::HaveCompiler;

use strict;
use warnings;
use Test2::V0 ();
use Capture::Tiny qw( capture_merged );
use parent qw( Exporter );

our @EXPORT_OK = qw( require_compiler );

{
  my $first = 1;
  sub require_compiler
  {
    my $skip;
    my($diag) = capture_merged {
        $skip = !ExtUtils::CBuilder->new->have_compiler;
    };
    Test2::V0::note $diag if defined $diag && $diag ne '';
    Test2::V0::skip_all 'test requires a compiler' if $skip;
  }
}

1;
