use strict;
use warnings;

package DateTime::TimeZone::HPUX;

use Carp qw/carp croak/;

our $VERSION = '1.00';

our @JAVA_PATHS = (
    '/opt/java1.4',
);

{
    my $_java_bin;
    my $_classes_dir;
sub _olson_from_java
{
    my $name;
    if (@_ && $_[0]) {
        $name = $_[0];
    }

    # Set the Java environment
    unless (defined $_classes_dir) {
        my $pm = __PACKAGE__.".pm";
        $pm =~ s!::!/!g;
        $pm = $INC{$pm};
        $_classes_dir = $pm;
        $_classes_dir =~ s/\.pm$//;
        
        foreach (
                (map { "$_/bin/java" } (exists $ENV{JAVA_HOME} ? ("$ENV{JAVA_HOME}/bin/java") : ()),
                                       @JAVA_PATHS),
                (map { "$_/java" } split(/:/, $ENV{PATH}) )
            ) {
            next unless -x "$_";
            $_java_bin = $_;
            last;
        }
    }

    unless (-r "$_classes_dir/TZ.class") {
        carp "Java class '$_classes_dir/TZ.class' not found.";
        return;
    }
    unless ($_java_bin) {
        carp "Java not found.";
        return;
    }

    my $olson;
    # Run the JVM to extract the mapping
    {
        local $ENV{TZ};
        $ENV{TZ} = $name if defined $name;
        $olson = qx!"$_java_bin" -cp "$_classes_dir" TZ!;
    }
    # Java returns "GMT" for unknown timezones
    return undef unless $olson =~ m!/!;
    chomp $olson;
    return $olson;
}
}


# Returns undef on failure, no exception
sub _hpux_to_olson
{
    my $tz = shift;
    local $@;
    eval { require 'DateTime/TimeZone/HPUX/JavaMap.pm' };
    return undef if $@;
    my $tz_name;
    if (exists $DateTime::TimeZone::HPUX::JavaMap::tz_map{$tz}) {
        $tz_name = $DateTime::TimeZone::HPUX::JavaMap::tz_map{$tz};
    } else {

        # Simple TZ without DST: we can extract reliably an offset
        # This is less clean than what Java /may/ return, but much more faster!
        if ($tz =~ /^([A-Z]{3,})(-?)([1-9]?\d(?::(\d{2}))?)(#\w+)?$/) {
            # Note that GMT+5 gives -0500 as it is how HP-UX handles it
            my ($name, $sign, $offset) = ($1, $2, $3);
            $offset = '0' . $offset if length $offset < 2;
            $offset .= '00' if length $offset == 2;
            # Build a TZ with DT::TZ::OffsetOnly
            # Signs are reversed
            $tz_name = ($sign eq '-' ? '+' : '-') . $offset;
        } else {
            carp("unknown timezone '$tz', trying to resolve it with Java (SLOOOOOW...)");
            $tz_name = _olson_from_java($tz);
        }
        if (defined $tz_name) {
            # Add to the cache
            $DateTime::TimeZone::HPUX::JavaMap::tz_map{$tz} = $tz_name;
        } else {
            return;
        }
    }

    # Build a DateTime::TimeZone object from a TZ name, catching exceptions
    # Returns undef if failure.
    local $@;
    return eval { DateTime::TimeZone->new(name => $tz_name) };
}


# Raise an exception on failure, like DateTime::TimeZone
sub new
{
    my %options = @_;
    croak("Missing 'name' argument") unless exists $options{name};
    my $name = $options{name};
    if ($name eq 'local') {
        return DateTime::TimeZone->new(%options);
    } else {
        my $tz = _hpux_to_olson($name);
        croak("unknown timezone '$tz'") unless defined $tz;
        return $tz;
    }
}



1;
__END__

=head1 NAME

DateTime::TimeZone::HPUX - Handles timezones defined at the operating system level on HP-UX

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

On an HP-UX system:

    my $tz =       DateTime::TimeZone->new(name => 'local');

    my $tz_paris = DateTime::TimeZone::HPUX->new(name => 'MET-1METDST');

=head1 DESCRIPTION

This distribution implement detection of the local timezone as defined at the
operating system level, either in $ENV{TZ} or in /etc/TIMEZONE.


HP-UX has its own system for defining timezones. See tztab(4). This is
incompatible with the now common set of timezones known as B<the Olson DB>
that is used by L<DateTime::TimeZone>.
This module fixes this hole by providing the map between the two systems.

=head1 IMPLEMENTATION

We are using the mapping provided by HP embedded in the Java Runtime
Environment:

=over 4

=item *

this is the only such map available on HP-UX (the other map I know in
/etc/dce_config doesn't uses Olson names)

=item *

we don't need to bundle our own map that could become obsolete

=item *

Java is supported by HP, so updated (at least patches are available),
so if the local Java has effectively been updated by the lazy administrator
(yes, I'm dreaming) DT::TZ::HPUX just has to be reinstalled (force install) and
you are not dependent on a new release from its maintainer.

=back

We are using the JRE at the module build time to generate a static Perl package
L<DateTime::TimeZone::HPUX::JavaMap> that contains a map of the known
timezones defined system wide (/usr/lib/tztab) to
Olson DB style timezone names that are known to Java and DateTime::TimeZone.

This extraction is done once for all at install time because JVM startup 
is SLOOOOOW... 


=head1 CAVEATS

=over 4

=item *

The module build uses a Java Runtime Environment if it finds one. This JRE
must be updated to the latest version with HP's patches for accurate results.
If a JRE is not found, a default map will be used but it may not be up to date.
If you find mapping problems, first update your JRE and rebuild DT::TZ::HPUX
with the environment variable JAVA_HOME pointing to it.

=item *

The module build use the JAVA_HOME environment variable as the prefered JRE
to use. Check that it is pointing to the latest JRE on the machine.

=item *

If you update the JRE, a new timezone mapping may be available. Security fixes
and timezone information updating are the most common cause of the publishing
of a new JRE.
So reinstalling DateTime::TimeZone::HPUX is advised if you update the JRE.

=item *

The JRE may also be used at runtime in extreme cases:

=over 4

=item -

TZ environment variable is not set and /etc/TIMEZONE is not available as a
fallback. The fix is to set $ENV{TZ}.

=item -

the sources above are avaiable, but have a value that was unknown at the module
build time (check L<DateTime::TimeZone::HPUX::JavaMap>). The fix is to rebuild
and reinstall the module (C<cpan force install DateTime::TimeZone::HPUX>).

=back



=back

=head1 SEE ALSO

=over 4

=item *

L<DateTime::TimeZone::Local::hpux> - Local timezone detection for HP-UX
(bundled in this distribution)

=item *

L<DateTime::TimeZone>

=back


=head1 BUGS

No known bug at this time. The module has an extensive test suite.

Please report any bugs or feature requests to C<bug-datetime-timezone-hpux at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DateTime-TimeZone-HPUX>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DateTime::TimeZone::HPUX


You can also look for information at:

=over 4

=item * The DateTime mailing list

L<http://datetime.perl.org/?MailingList>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DateTime-TimeZone-HPUX>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DateTime-TimeZone-HPUX>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DateTime-TimeZone-HPUX>

=item * Search CPAN

L<http://search.cpan.org/dist/DateTime-TimeZone-HPUX/>

=back

=head1 AUTHOR

Olivier MenguE<eacute>, C<< <dolmen at cpan.org> >>


=head1 COPYRIGHT & LICENSE

Copyright 2009 Olivier MenguE<eacute>, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
