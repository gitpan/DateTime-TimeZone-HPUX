use strict;
use warnings;

use Test::More tests => 7;

# Simulate locale environment
local $^O = 'hpux';
local $ENV{TZ} = 'MET-1METDST';

use DateTime::TimeZone;

my $tz1 = DateTime::TimeZone->new( name => 'local' );
isa_ok( $tz1, 'DateTime::TimeZone' );
my $tz2 = DateTime::TimeZone->new( name => 'Europe/Paris' ); 
isa_ok( $tz2, 'DateTime::TimeZone' );
is( $tz1->has_dst_changes, $tz2->has_dst_changes(), 'DST changes' );


SKIP: {
    my $version = '0.1501';
    eval "use DateTime $version";
    skip "Cannot run tests before DateTime.pm $version is installed.", 4 if $@;

	my @dt = (
        {
            year => 2009, month => 3, day => 29,
            hour => 0, minute => 59,
            time_zone => 'UTC'
        }, {
            year => 2009, month => 3, day => 29,
            hour => 1, minute =>  1,
            time_zone => 'UTC'
        }, {
            year => 2009, month => 10, day => 25,
            hour => 1, minute => 59,
            time_zone => 'UTC'
        }, {
            year => 2009, month => 10, day => 25,
            hour => 2, minute =>  1,
            time_zone => 'UTC'
        }
    );

    foreach my $dt_args (@dt) {
    	my $dt = DateTime->new(%$dt_args);
        my $dt_txt = $dt->iso8601 . "Z";
        $dt->set_time_zone($tz1);
        my $hour1 = $dt->hour;
        $dt->set_time_zone($tz2);
        my $hour2 = $dt->hour;
        is( $hour1, $hour2, "Same local hour for $dt_txt: $hour1");
    }
}


