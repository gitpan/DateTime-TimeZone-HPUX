use strict;
use warnings;

use Test::More;

plan skip_all => "not HP-UX or missing environment variable TZ" if $^O ne 'hpux' || ! exists $ENV{TZ};

plan tests => 1;

use DateTime::TimeZone;

my $tz1 = DateTime::TimeZone->new( name => 'local' );
isa_ok( $tz1, 'DateTime::TimeZone' );
