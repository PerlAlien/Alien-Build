use strict;
use warnings;
use Test::More;

require_ok 'alienfile';
require_ok 'Alien::Build';
require_ok 'Alien::Base2';
require_ok 'Alien::Build::Interpolate';
require_ok 'Alien::Build::Interpolate::Default';
require_ok 'Alien::Build::Plugin';
require_ok 'Alien::Build::Plugin::Autoconf';
require_ok 'Alien::Build::Plugin::MSYS';
require_ok 'Alien::Build::Plugin::Fetch::LWP';
require_ok 'Alien::Build::Plugin::Fetch::FTP';
require_ok 'Alien::Build::Plugin::Decode::HTML';
require_ok 'Alien::Build::Plugin::Decode::DirListing';
require_ok 'Alien::Build::Plugin::Decode::DirListingFtpcopy';

done_testing;
