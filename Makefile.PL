use inc::Module::Install 0.77;

use strict;
use warnings;

name 'Parse-Method-Signatures';
all_from 'lib/Parse/Method/Signatures.pm';

requires 'Text::Balanced' => 2.000000;

test_requires 'Test::More';
test_requires 'Test::Differences';
test_requires 'Test::Exception';

auto_install;
WriteAll;