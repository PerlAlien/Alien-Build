use Test2::Bundle::Extended;
use LZMA::Example;

my $version = lzma_version_string();

ok $version, 'returns a version';
note "version = $version";

done_testing;
