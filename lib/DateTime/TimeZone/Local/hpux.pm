package DateTime::TimeZone::Local::hpux;

use strict;
use warnings;

# Debugging flags, used in the testsuite
BEGIN {
    defined &SKIP_ETC_TIMEZONE or *SKIP_ETC_TIMEZONE = sub () { 0 };
    defined &SKIP_JAVA or *SKIP_JAVA = sub () { 0 };
}



use base 'DateTime::TimeZone::Local';
use DateTime::TimeZone::HPUX;

sub Methods
{
    qw( _FromEnv _FromEtcTIMEZONE _FromJava )
}

# TODO Build the full timezone database from /usr/lib/tztab
sub _FromEnv
{
    return unless exists $ENV{TZ};
    DateTime::TimeZone::HPUX::_hpux_to_olson($ENV{TZ})
}

sub _FromEtcTIMEZONE
{
    return if SKIP_ETC_TIMEZONE;

    my $tz_file = '/etc/TIMEZONE';

    return unless -f $tz_file && -r _;

    local *TZ;
    open TZ, "<$tz_file"
        or die "Cannot read $tz_file: $!";

    my $name;
    while ( defined( $name = <TZ> ) )
    {
        if ( $name =~ /\A\s*TZ\s*=\s*(\S+)/ )
        {
            $name = $1;
            last;
        }
    }
    close TZ;

    DateTime::TimeZone::HPUX::_hpux_to_olson($name)
}

# Retrieve the default timezone using Java (java.util.TimeZone.getDefault())
sub _FromJava
{
    return if SKIP_JAVA;
    warn('Retrieving default timezone using Java (SLOOOOOW)... You should instead set $ENV{TZ}');
    my $tz_name = DateTime::TimeZone::HPUX::_olson_from_java();
    return unless defined $tz_name;

    # Build a DT::TZ object from the name returned by Java
    local $@;
    return eval { DateTime::TimeZone->new(name => $tz_name) };
}


1;
__END__

=head1 NAME

DateTime::TimeZone::Local::hpux - Local timezone detection for HP-UX

=head1 VERSION

$Id: hpux.pm,v 1.7 2009/10/14 17:29:04 omengue Exp $

=head1 SYNOPSIS

This is a workaround for bug RT#44721.

The fix for bug RT#44724 must have been applied (fixed in DateTime::TimeZone 0.87).

=head1 METHODS

=head2 Methods()

See L<DateTime::TimeZone::Local>

=head1 SEE ALSO

=over 4

=item C<man 4 tztab>

=item C</usr/lib/tztab>

=item L<http://rt.cpan.org/Public/Bug/Display.html?id=44721>

=item L<http://rt.cpan.org/Public/Bug/Display.html?id=44724>

=back

=head1 BUGS

The current implementation is simply a hard coded mapping between the tztab
I found on my system to the Olson DB. This means that the TimeZone returned
may not directly match the definition in /usr/lib/tztab.
I consider this as a feature as DateTime::TimeZone is actively maintained,
probaly much more than your local tztab.


=head1 AUTHOR

Olivier MenguE<eacute>, C<< <dolmen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-datetime-timezone-hpux at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DateTime-TimeZone-HPUX>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DateTime::TimeZone::Local::hpux


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DateTime-TimeZone-HPUX>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DateTime-TimeZone-HPUX>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DateTime-TimeZone-HPUX>

=item * Search CPAN

L<http://search.cpan.org/dist/DateTime-TimeZone-HPUX/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Olivier MenguE<eacute>, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
