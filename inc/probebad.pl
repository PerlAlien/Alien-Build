use strict;
use warnings;
use ExtUtils::CBuilder;
use ExtUtils::ParseXS;

# probebad.pl: this is intended to be run by Makefile.PL to find FAIL reports
# that commonly come from cpantesters, but are in fact the result of badly
# configured environments.  Usually I try to contact the testers in quesion,
# but sometimes they are either unable or unwilling to respond, and I don't
# want to waste my time re-diagnosing the same errors.

my $cb = ExtUtils::CBuilder->new;

if($cb->have_compiler)
{
  my $pxs = ExtUtils::ParseXS->new;
  eval {
    $pxs->process_file(
      filename     => "inc/trivial.xs",
      output       => "inc/trivial.c",
      versioncheck => 0,
      prototypes   => 0,
    );
  };

  if(my $error = $@)
  {
    print "Configuration unsupported\n";
    print "You appear to have a C compiler, but I am unable to process a\n";
    print "trivial XS file, errored with:\n";
    print "$error\n";
    exit;
  }
  
  if($pxs->report_error_count != 0)
  {
    print "Configuration unsupported\n";
    print "You appear to have a C compiler, but there were errors processing\n";
    print "a trivial XS file.\n";
    exit;
  }
  
  my($cc_out, $obj, $cc_exception) = capture_merged(
    sub {
      my $obj = eval {
        $cb->compile(
          source => "inc/trivial.c",
        );
      };
      ($obj, $@);
    }
  );
  
  if(! $obj)
  {
    print "Configuration unsupported\n";
    print "You appear to have a C compiler, but there were errors processing\n";
    print "the C file generated from a trivial XS file.\n";
    if($cc_exception)
    {
      print "Exception:\n";
      print "$cc_exception\n";
    }
    if($cc_out)
    {
      print "Compiler output:\n";
      print "$cc_out\n";
    }
    exit;
  }
  
  # cleanup
  unlink 'inc/trivial.c';
  unlink $obj;

}

sub capture_merged
{
  # I don't want to make Capture::Tiny a configure require, but
  # I also don't want to spew compiler output where the probe is
  # okay.  Compromise by using it if it is already installed.
  if(eval { require Capture::Tiny })
  {
    goto \&Capture::Tiny::capture_merged;
  }
  else
  {
    my($code) = @_;
    return ('', $code->());
  }
}

1;
