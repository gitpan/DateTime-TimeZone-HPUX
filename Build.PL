#!/usr/bin/env perl
use utf8;  # vim:set ts=4 sw=4:

use strict;
use warnings;

use Module::Build;

Module::Build->new(
    module_name         => 'DateTime::TimeZone::HPUX',
    dist_author         => 'Olivier Mengué <dolmen@cpan.org>',
    license             => 'perl',
    requires => {
        'DateTime::TimeZone' => '>=0.87',
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup => [ 'cover_db', '*~', '.*~', 'Makefile', 'MANIFEST.bak' ],
    create_makefile_pl => 'traditional',
)->create_build_script();
