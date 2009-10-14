#!/usr/bin/env perl
use utf8;  # vim:set ts=4 sw=4:

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    module_name         => 'DateTime::TimeZone::HPUX',
    dist_author         => 'Olivier Mengué <dolmen@cpan.org>',
    license             => 'perl',
    requires => {
        'DateTime::TimeZone' => '>=0.87',
        'Carp' => 0,
    },
    build_requires => {
        'Test::More' => 0,
        'File::Basename' => 0,
    },
    PL_files => {
	'JavaMap.PL' => 'lib/DateTime/TimeZone/HPUX/JavaMap.pm',
    },
    add_to_cleanup => [ 'cover_db', '*~', '.*~', 'Makefile', 'MANIFEST.bak' ],
    create_makefile_pl => 'traditional',
);
# Install Java class files (lib/DateTime/TimeZone/HPUX/TZ.class)
$build->add_build_element('class');
$build->create_build_script();
