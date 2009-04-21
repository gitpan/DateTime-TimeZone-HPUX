use inc::Module::Install;

name     'DateTime-TimeZone-HPUX';
all_from 'lib/DateTime/TimeZone/HPUX.pm';
author   'Olivier Mengué <dolmen@cpan.org>';
license  'perl';

requires 'DateTime::TimeZone' => '0.87';
build_requires 'Test::More';

auto_install;

WriteAll;
