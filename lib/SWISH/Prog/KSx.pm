package SWISH::Prog::KSx;
use strict;
use warnings;

our $VERSION = '0.01';

=head1 NAME

SWISH::Prog::KSx - Swish3 KinoSearch backend

=head1 SYNOPSIS

 # create an index
 use SWISH::Prog;
 my $indexer = SWISH::Prog->new(
    invindex   => 'path/to/index.swish',
    aggregator => 'fs',
    indexer    => 'ks',
    config     => 'path/to/swish.conf',
 );
 
 $indexer->index('path/to/files');
 
 
 # then search the index
 my $searcher = SWISH::Prog::Xapian::Searcher->new(
    invindex => 'path/to/index.swish',
    config   => 'path/to/swish.conf',
 );
 my $results = $searcher->search('my query')
 while ( my $result = $results->next ) {
    printf("%s : %s\n", $result->score, $result->uri);
 }


=head1 DESCRIPTION

SWISH::Prog::KSx is a KinoSearch-based implementation of Swish3,
using the SWISH::3 bindings for libswish3.

See the Swish3 development site at http://dev.swish-e.org/wiki/swish3

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-swish-prog-ksx at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SWISH-Prog-KSx>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SWISH::Prog::KSx

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SWISH-Prog-KSx>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SWISH-Prog-KSx>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SWISH-Prog-KSx>

=item * Search CPAN

L<http://search.cpan.org/dist/SWISH-Prog-KSx/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;    # End of SWISH::Prog::KSx
