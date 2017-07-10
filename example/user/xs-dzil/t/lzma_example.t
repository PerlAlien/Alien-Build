use Test2::V0;
use LZMA::Example;

my $version = lzma_version_string();

ok $version, 'returns a version';
note "version = $version";

done_testing;
