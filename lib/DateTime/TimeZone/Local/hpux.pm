package DateTime::TimeZone::Local::hpux;

use strict;
use warnings;

use base 'DateTime::TimeZone::Local';

sub Methods
{
    qw( FromEnv FromEtcTIMEZONE )
}

# TODO Build the full timezone database from /usr/lib/tztab
sub FromEnv
{
    tztab_to_Olson($ENV{TZ})
}

sub FromEtcTIMEZONE
{
    # Borrowed from DateTime::TimeZone::Local::Unix

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

    return tztab_to_Olson($name);
}



{
    # See settimezone() in /etc/dce_config for a basic map
    # sed -n '/"[A-Z].*tzfile=/ s/^.*"\([^"]*\)".*"\([^"]*\)".*$/		'\''\1'\'' => '\''\2'\''/p' /etc/dce_config
    # See also:
    # grep '^[A-Z#]' /usr/lib/tztab
    my %tztab_to_Olson = (
        'MET-1METDST' => 'Europe/Paris',
        'AST4' => 'America/Guadeloupe',
        'GFT3' => 'America/Cayenne',
        'EAT-3' => 'Indian/Mayotte',
        'RET-4' => 'Indian/Reunion',
        'GAMT-9' => 'Pacific/Gambier',
        'MART-9:30' => 'Pacific/Marquesas',
        'NCT-11' => 'Pacific/Noumea',
        'TAHT10' => 'Pacific/Tahiti',
        'PMST3PMDT' => 'America/Miquelon',
        'WET0WETDST' => 'Europe/Lisbon',
        'PWT0PST' => 'Europe/Lisbon',
        'GMT0BST' => 'Europe/London',
        'PST8PDT' => 'PST',
        'YST9YDT' => 'America/Whitehorse',
        'SAST-2' => 'Africa/Johannesburg',
        'WST-3WSTDST' => 'Europe/Moscow',
        'WST-2WSTDST' => 'Europe/Minsk',
        'WST-4WSTDST' => 'Europe/Samara',
        'WST-5WSTDST' => 'Asia/Yekaterinburg',
        'WST-6WSTDST' => 'Asia/Omsk',
        'WST-7WSTDST' => 'Asia/Krasnoyarsk',
        'WST-8WSTDST' => 'Asia/Irkutsk',
        'WST-9WSTDST' => 'Asia/Yakutsk',
        'WST-10WSTDST' => 'Asia/Vladivostok',
        'WST-11WSTDST' => 'Asia/Magadan',
        'WST-12WSTDST' => 'Asia/Kamchatka',
    );

    sub tztab_to_Olson
    {
        my $tz = shift;
        # A known timezone that we map to the Olson DB name
        if (exists $tztab_to_Olson{$tz}) {
            $tz = $tztab_to_Olson{$tz};
        # A timezone without DST
        # Note that GMT+5 gives -0500 as it is how HP-UX handles it
        } elsif ($tz =~ /^([A-Z]{3,})(-?)([1-9]?\d(?::(\d{2}))?)$/) {
            my ($name, $sign, $offset) = ($1, $2, $3);
            $offset = '0' . $offset if length $offset < 2;
            $offset .= '00' if length $offset == 2;
            # Build a TZ with DT::TZ::OffsetOnly
            # Signs are reversed
            #$tz = ($sign eq '-' ? '+' : '-') . $offset . (length $offset > 2 ? '' : '00');
            $tz = ($sign eq '-' ? '+' : '-') . $offset;
        # An unknown timezone with DST
        } elsif ($tz =~ /^([A-Z]+)-?[1-9]?[0-9]/) {
            # TODO build a TimeZone object from the tztab content
            $tz = $1;
        } else {
            return;
        }
        local $@;
        return eval { DateTime::TimeZone->new(name => $tz) };
    }
}

1;
__END__

=head1 NAME

DateTime::TimeZone::Local::hpux - Local timezone detection for HP-UX

=head1 VERSION

$Id: hpux.pm,v 1.3 2009/04/21 17:20:37 omengue Exp $

=head1 SYNOPSIS

This is a workaround for bug RT#44721.

The fix for bug RT#44724 must have been applied (fixed in DateTime::TimeZone 0.87).

=head1 SEE ALSO

=over 4

=item C<man 5 tztab)>

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
