#!/usr/bin/perl
use strict;
use warnings;

use File::Basename;
use DateTime::TimeZone;

use lib 'lib';
use DateTime::TimeZone::HPUX;

# This script generates a static Perl package that contains a map of the known
# timezones defined system wide (/usr/lib/tztab) to Olson DB style timezone
# names that are hopefully known to DateTime::TimeZone.
# We uses Java for this conversion:
# - this is the only such map available on HP-UX (the other map I know in
#   /etc/dce_config doesn't uses Olson names)
# - we don't need to bundle our own map that could become obsolete
# - Java is supported by HP, so updated (at least patches are available),
#   so if the local Java has effectively been updated (yes, I'm dreaming)
#   DT::TZ::HPUX just has to be reinstalled (force install) and you are not
#   dependent on a new release from its maintainer.
#
# This extraction is done once for all at install time because JVM startup
# is SLOOOOOW...
# So reinstalling DateTime::TimeZone::HPUX is advised if you update Java.
#
# The script is designed to be resistant to the absence of any Java on the
# machine.

exit 1 unless @ARGV;

# ARG0: output file (Perl package)
my $java_map = $ARGV[0];
# ARG1: tztab file (optional)
my $tztab = @ARGV > 1 ? $ARGV[1] : '/usr/lib/tztab';


print "Building map '$java_map'...\n";

my %tz_olson_map;


# Merge the default map that was generated by the distributor
if (-r 'inc/DefaultMap.pm') {
    eval q{
        require 'inc/DefaultMap.pm'
            and @tz_olson_map{keys %DefaultMap::tz_map} = values %DefaultMap::tz_map;
    };
    # Failure is not a problem
    warn $@ if ($@);
}

# Our built-in map
my %tz_olson_map_builtin = (
    # French areas
    'AST4' => 'America/Guadeloupe', # Also America/Martinique
    'GFT3' => 'America/Cayenne',
    'EAT-3' => 'Indian/Mayotte',
    'RET-4' => 'Indian/Reunion',
    'GAMT-9' => 'Pacific/Gambier',
    'MART-9:30' => 'Pacific/Marquesas',
    'NCT-11' => 'Pacific/Noumea',
    'TAHT10' => 'Pacific/Tahiti',
    'PMST3PMDT' => 'America/Miquelon',
    # Unknown to Java. Also 'Asia/Kuching'.
    'PST-8PDT' => 'Asia/Singapore',
    # This was a bogus TZ according to tztab, same as EST5CDT
    'EST6CDT' => 'America/Indianapolis',
    # FIXME Do more check on all the 13 following mappings
    'CST6CDT#Indiana' => 'America/Indianapolis',
    'EST5EDT#Indiana' => 'America/Indianapolis',
    'MXST6MXDT' => 'America/Mexico_City',
    # {{{ From http://beechglen.com/hpux/tztab2k7.txt
    'MXST6MXDT#Mexico' => 'America/Mexico_City',
    # Labrador
    'AST4ADT#Canada' => 'America/Goose_Bay',
    'CSM6CDM' => 'America/Mexico_City',
    'CST6CDT#Mexico' => 'America/Mexico_City',
    'MSM7MDM' => 'America/Chihuahua',
    'MST7MDT#Mexico' => 'America/Chihuahua',
    # Newfoundland
    'NST3:30NDT#Canada' => 'America/St_Johns',
    'PSM8PDM' => 'America/Tijuana',
    'PST8PDT#Mexico' => 'America/Tijuana',
    'WST-8WDT' => 'Australia/Perth',
    # }}}
);
# Merge it
@tz_olson_map{keys %tz_olson_map_builtin} = values %tz_olson_map_builtin;


my @tztab;

push @tztab, $ENV{TZ} if exists $ENV{TZ};

if (-r $tztab) {

    # Load list of timezones supported on the system
    # See: grep '^[A-Z#]' /usr/lib/tztab
    open TZTAB, '<', $tztab;
    while (<TZTAB>) {
        next unless /^[A-Z]/;
        unless (/^(([A-Z]{3,})(?:-?[1-9]?\d(?::\d{2})?([A-Z]{3,})?)?(#\w+)?)/) {
            print "Ignoring $_";
            last
        }
        my ($tz) = ($1);
        push @tztab, $tz;
        #print "$tz\n";
    }
    close TZTAB;
}

if (@tztab) {
    # Look for the first Java
    # TODO look for the most recent version among those found: it is the one
    # with the more recent map
    my $java_bin;
    foreach my $bin (
        (exists $ENV{'JAVA_HOME'} ? "$ENV{JAVA_HOME}/bin/java" : ()),
        '/opt/java1.4/bin/java',
        (map { "$_/java" } split(/:/, $ENV{PATH})),
    ) {
        next unless -x "$bin";
        $java_bin = "$bin";
        last;
    }


    #$java_bin = "java";

    # For each timezone, call the Java runtime to convert the environment
    # variable to something that look like an Olson DB name and that we
    # hope will be known to DateTime::TimeZone.
    if ($java_bin) {
        print "Mapping HPUX timezones to Olson DB using Java ($java_bin)...\n";
        foreach my $tz (@tztab) {
            #my $tz_olson = DateTime::TimeZone::HPUX::_olson_from_java($tz);
            local $ENV{TZ} = $tz;
            my $tz_olson = qx!"$java_bin" -cp "lib/DateTime/TimeZone/HPUX" TZ!;
            chomp $tz_olson;
            next unless defined $tz_olson;
            next unless $tz_olson =~ m!/!;
            print "  $tz: $tz_olson\n";
            print "    (overrides our builtin value $tz_olson_map{$tz})\n" if exists $tz_olson_map{$tz} && $tz_olson ne $tz_olson_map{$tz};
            $tz_olson_map{$tz} = $tz_olson;
        }
    } else {
        print "Java not found => skipped\n";
    }

} else {
    print "'$tztab' not found => skipped\n";
    print "Using default map only.\n";
}

@tztab = sort grep { ! exists $tz_olson_map{$_} } @tztab;
if (@tztab) {
    warn "Warning! The following timezones have no match:\n";
    foreach my $tz (@tztab) {
        warn "  $tz\n";
    }
}

# Check that the values exist in DateTime::TimeZone

foreach my $name (sort keys %tz_olson_map) {
    my $tz_olson = $tz_olson_map{$name};
    my $tz = eval { DateTime::TimeZone->new(name => $tz_olson); };
    if ($@) {
        warn "Invalid TZ map value for $name => $tz_olson: $@";
        delete $tz_olson_map{$name};
    } elsif (! defined($tz) || ! $tz->isa('DateTime::TimeZone') || ! $tz->is_olson ) {
        warn "Invalid TZ map value for $name => $tz_olson";
        delete $tz_olson_map{$name};
    }
}



# Extract the package name from the file path
# A package name component starts with an upper case letter, but container
# dir starts with a lower case.
sub package_from_file
{
    my $pkg = $_[0];
    $pkg =~ s/\.pm$//;
    $pkg =~ s!^(.*[/\\])?[^A-Z][^/\\]*[/\\]!!;
    $pkg =~ s![/\\]!::!g;
    return $pkg;
}



my $pkg = package_from_file($java_map);


print "Writing package $pkg to '$java_map'...\n";

my $dir = dirname($java_map);
mkdir $dir, 0755 unless -d $dir;

my @t = localtime;
my $version = sprintf "%4d%02d%02d.%02d", 1900+$t[5], $t[4]+1, $t[3], $t[2];

my (@list_perl, @list_pod);
foreach (sort keys %tz_olson_map) {
    push @list_perl, "\n    '$_' => '$tz_olson_map{$_}',";
    push @list_pod, sprintf "\n    %-20s  %s", $_, $tz_olson_map{$_};
}

my $template = <<EOB;
|# Generated at install time by JavaMap.PL
|# $^X $0 $java_map $tztab
|use strict;
|use warnings;
|package $pkg;
|
|our \$VERSION = '$version';
|
|# Maps HP-UX timezone names to Olson DB names
|our \%tz_map = (@list_perl
|);
|
|1;
|__END__
|
|=head1 NAME
|
|$pkg - Mapping of HPUX timezones to DateTime::TimeZone names
|
|=head1 VERSION
|
|$version
|
|=head1 SYNOPSIS
|
|This is a private module of L<DateTime::TimeZone::HPUX> that has no public API.
|
|=head1 DESCRIPTION
|
|This module has been generated by JavaMap.PL at install time of
|L<DateTime::TimeZone::HPUX> from F</usr/lib/tztab> and the Java Runtime
|Environment mapping.
|
|The following mapping has been recorded:
|@list_pod
|
|If your timezone is not in this list:
|
|=over 4
|
|=item *
|
|Check that the timezone is declared when you build the module:
|
|=over 4
|
|=item - in F</usr/lib/tztab>. See tztab(4) for the file format.
|
|=item - in \$ENV{TZ}
|
|=back
|
|=item *
|
|Check that the timezone is supported by your JRE (the F<TZ.class> file is
|bundled in the DateTime::TimeZone::HPUX distribution and installed in the same
|directory than this module):
|
|    TZ=I<timezone> java -cp I<directory> TZ
|
|If not, update your JRE by installing HP's patches from
|L<http://docs.hp.com/en/HPUXJAVAPATCHES/>
|
|=item *
|
|Rebuild DT::TZ::HPUX:
|
|    cpan> force install DateTime::TimeZone::HPUX
|
|=back
|
|=head1 SEE ALSO
|
|L<DateTime::TimeZone::HPUX>
|
|=cut
EOB

$template =~ s/^\|//gm;

# Create the package
open JAVAMAP, '>', $java_map or die "Error opening '$java_map': $!";
print JAVAMAP $template;
close JAVAMAP;

print "Done.\n";

__END__
vim:set et sw=4 sts=4:
