#!perl -T

use strict;
use warnings;
use Test::More tests => 2;

BEGIN {
	use_ok( 'DateTime::TimeZone::HPUX' );
	use_ok( 'DateTime::TimeZone::Local::hpux' );
}

diag( "Testing DateTime::TimeZone::HPUX $DateTime::TimeZone::HPUX::VERSION, Perl $], $^X" );
