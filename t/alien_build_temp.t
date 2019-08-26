use Test2::V0 -no_srand => 1;
use Alien::Build::Temp;

my $dir = Alien::Build::Temp->newdir;
ok -d $dir;
note "dir = $dir";

my $fh = Alien::Build::Temp->new;
close $fh;
note "file = @{[ $fh->filename ]}";

done_testing;
