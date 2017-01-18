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

done_testing;
