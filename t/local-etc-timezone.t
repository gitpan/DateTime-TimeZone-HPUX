use strict;
use warnings;

use Test::More;

plan skip_all => "not HP-UX or missing /etc/TIMEZONE" if $^O ne 'hpux' || ! -f '/etc/TIMEZONE';

plan tests => 1;

local $ENV;
delete $ENV{TZ};

use DateTime::TimeZone;

my $tz1 = DateTime::TimeZone->new( name => 'local' );
isa_ok( $tz1, 'DateTime::TimeZone' );
