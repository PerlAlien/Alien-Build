use strict;
use warnings;
use File::Temp qw( tempdir );
use File::chdir;
use Path::Tiny qw( path );
use Capture::Tiny qw( capture_merged );

sub run
{
  my @cmd = @_;

  my($out, $exit) = capture_merged {
    print "+@cmd\n";
    system @cmd;
    $?;
  };
  if($exit)
  {
    print $out;
    print STDERR "command failed\n";
    exit 2;
  }
}

{
  local $CWD = tempdir( CLEANUP => 1 );

  path('xx.txt')->spew("xx\n");

  run 'tar', 'cvf', 'xx.tar', 'xx.txt';
  run 'cp', 'xx.tar', 'xx.tar.bak';
  run 'compress', 'xx.tar';
  run 'mv', 'xx.tar.bak', 'xx.tar';
  run 'gzip', '-k', 'xx.tar';
  run 'bzip2', '-k', 'xx.tar';
  run 'xz', '-k', 'xx.tar';
  run 'zip', 'xx.zip', 'xx.txt';
  run 'rm', '-f', 'xx.txt';

  foreach my $file (sort { $a->basename cmp $b->basename } path('.')->children)
  {
    my $content = $file->slurp_raw;
    print "[ @{[ $file->basename ]} ]\n";
    print pack('u', $content), "\n\n";
  }
}
