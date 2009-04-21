#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DateTime::TimeZone::Local::hpux' );
}

diag( "Testing DateTime::TimeZone::Local::hpux $DateTime::TimeZone::Local::hpux::VERSION, Perl $], $^X" );
