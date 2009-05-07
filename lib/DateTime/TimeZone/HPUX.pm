package DateTime::TimeZone::HPUX;

our $VERSION = '0.06';

1;

=head1 NAME

DateTime::TimeZone::HPUX - Handles timezones defined at the operating system level on HP-UX

=head1 SYNOPSIS

On an HP-UX system:

    my $tz = DateTime::TimeZone->new(name => 'local');

=head1 SEE ALSO

L<DateTime::TimeZone::Local::hpux> - Local timezone detection for HP-UX
(bundled in this distribution)

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


=head1 COPYRIGHT & LICENSE

Copyright 2009 Olivier MenguE<eacute>, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
