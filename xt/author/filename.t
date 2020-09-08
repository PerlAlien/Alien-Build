use Test2::V0 -no_srand => 1;
use File::chdir;
use File::Find qw( find );
use File::Basename qw( basename );

my $basename = basename $CWD;

my $dev = $basename =~ /^([A-Z]+)(-[A-Z]+)*$/i;

local $CWD = '..';

find(sub {
  my $path = $File::Find::name;
  return if $path =~ /^$basename\/\./;
  return if $dev && $path =~ /^$basename\/$basename-/;
  my $length = length($path);
  cmp_ok $length, '<', 100, "$path";
}, $basename);

note "dev = $dev";

done_testing;
