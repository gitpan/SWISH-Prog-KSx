package SWISH::Prog::KSx::Indexer;
use strict;
use warnings;

our $VERSION = '0.05';

use base qw( SWISH::Prog::Indexer );
use SWISH::Prog::KSx::InvIndex;

use KinoSearch::Indexer;
use KinoSearch::Schema;
use KinoSearch::Analysis::PolyAnalyzer;
use KinoSearch::FieldType::FullTextType;
use KinoSearch::FieldType::StringType;

use Carp;
use SWISH::3 qw( :constants );
use Scalar::Util qw( blessed );
use Data::Dump qw( dump );

=head1 NAME

SWISH::Prog::KSx::Indexer - Swish3 KinoSearch indexer

=head1 SYNOPSIS

 use SWISH::Prog::KSx::Indexer;
 my $indexer = SWISH::Prog::KSx::Indexer->new(
    config      => SWISH::Prog::Config->new(),
    invindex    => SWISH::Prog::KSx::InvIndex->new(),
    
 );

=head1 DESCRIPTION

SWISH::Prog::KSx::Indexer is a KinoSearch-based indexer
class for Swish3.

=head1 METHODS

Only new and overridden methods are documented here. See
the L<SWISH::Prog::Indexer> documentation.

=head2 init

Implements basic object set up. Called internally by new().
If you override this method, be sure to call SUPER::init(@_) or the
equivalent.

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    $self->{invindex} ||= SWISH::Prog::KSx::InvIndex->new;

    if ( $self->{invindex} && !blessed( $self->{invindex} ) ) {
        $self->{invindex}
            = SWISH::Prog::KSx::InvIndex->new( path => $self->{invindex} );
    }

    unless ( $self->invindex->isa('SWISH::Prog::KSx::InvIndex') ) {
        croak ref($self)
            . " requires SWISH::Prog::Xapian::InvIndex-derived object";
    }

    # config resolution order
    # 1. default config via SWISH::3->new

    # TODO can pass s3 in?
    $self->{s3} ||= SWISH::3->new(
        handler => sub {
            $self->_handler(@_);
        }
    );

    #SWISH::3->describe( $self->{s3} );

    # 2. any existing header file.
    my $swish_3_index
        = $self->invindex->path->file( SWISH_HEADER_FILE() )->stringify;

    if ( -r $swish_3_index ) {
        $self->{s3}->config->add($swish_3_index);
    }

    # 3. via 'config' param passed to this method
    if ( exists $self->{config} ) {

        # this utility method defined in base SWISH::Prog::Indexer class.
        $self->_verify_swish3_config();
    }

    # 4. always turn off tokenizer, preferring KS do it
    $self->{s3}->analyzer->set_tokenize(0);

    my $config = $self->{s3}->config;
    my $lang = $config->get_index->get( SWISH_INDEX_STEMMER_LANG() ) || 'en';
    $self->{_lang} = $lang;    # cache for finish()
    my $schema = KinoSearch::Schema->new();
    my $analyzer
        = KinoSearch::Analysis::PolyAnalyzer->new( language => $lang, );

    # build the KS fields, which are a merger of MetaNames+PropertyNames
    my %fields;

    my $metanames = $config->get_metanames;
    for my $name ( @{ $metanames->keys } ) {

        #my $metaname = $metanames->get($name);
        $fields{$name}->{is_meta} = 1;
    }

    my $properties = $config->get_properties;
    for my $name ( @{ $properties->keys } ) {
        my $property = $properties->get($name);
        $fields{$name}->{is_prop} = 1;
        if ( $property->sort ) {
            $fields{$name}->{sortable} = 1;
        }
    }

    #dump( \%fields );

    my $metaname_plus_prop = KinoSearch::FieldType::FullTextType->new(
        analyzer      => $analyzer,
        highlightable => 1,
    );
    my $metaname_only = KinoSearch::FieldType::FullTextType->new(
        analyzer => $analyzer,
        stored   => 0,
    );
    my $property_only
        = KinoSearch::FieldType::StringType->new( sortable => 1, );
    my $store_no_sort = KinoSearch::FieldType::StringType->new(
        sortable => 0,
        stored   => 1,
    );

    for my $name ( keys %fields ) {
        my $field = $fields{$name};
        if ( $field->{is_meta} and !$field->{is_prop} ) {
            $schema->spec_field(
                name => $name,
                type => $metaname_only
            );
        }
        elsif ( $field->{is_meta} and $field->{is_prop} ) {
            $schema->spec_field(
                name => $name,
                type => $metaname_plus_prop
            );
        }
        elsif (!$field->{is_meta}
            and $field->{is_prop}
            and !$field->{sortable} )
        {
            $schema->spec_field(
                name => $name,
                type => $store_no_sort
            );
        }
        elsif (!$field->{is_meta}
            and $field->{is_prop}
            and $field->{sortable} )
        {
            $schema->spec_field(
                name => $name,
                type => $property_only
            );
        }
    }

    for my $d ( SWISH_DOC_FIELDS() ) {
        unless ( exists $fields{$d} ) {
            $schema->spec_field( name => $d, type => $property_only );
        }
    }

    # TODO can pass ks in?
    $self->{ks} ||= KinoSearch::Indexer->new(
        schema => $schema,
        index  => $self->invindex->path,
        create => 1,
    );

    return $self;
}

=head2 process( I<doc> )

Overrides base method to parse the I<doc> (a SWISH::Prog::Doc object)
with the SWISH::3 parse_buffer() method.

=cut

sub process {
    my $self = shift;
    my $doc  = $self->SUPER::process(@_);
    $self->{s3}->parse_buffer("$doc");
    return $doc;
}

sub _handler {
    my ( $self, $data ) = @_;
    my %doc;
    for my $d ( SWISH_DOC_FIELDS() ) {
        $doc{$d} = $data->doc->$d;
    }
    my $metas = $data->metanames;

    for my $m ( keys %$metas ) {
        $doc{$m} = join( "\n", @{ $metas->{$m} } );
    }

    # TODO flesh %doc out with properties
    #warn dump \%doc;

    $self->{ks}->add_doc( \%doc );
}

=head2 finish

Calls commit() on the internal KinoSearch::Indexer object,
writes the C<swish.xml> header file and calls the superclass finish()
method.

=cut

sub finish {
    my $self = shift;

    return 0 if $self->{_is_finished};

    # commit our changes
    $self->{ks}->commit();

    # write header
    my $index = $self->{s3}->config->get_index;

    $index->set( SWISH_INDEX_NAME(),         $self->invindex->path );
    $index->set( SWISH_INDEX_FORMAT(),       'KSx' );
    $index->set( SWISH_INDEX_STEMMER_LANG(), $self->{_lang} );

    $self->{s3}->config->write(
        $self->invindex->path->file( SWISH_HEADER_FILE() )->stringify );

    $self->{s3} = undef;    # invalidate this indexer

    $self->SUPER::finish(@_);

    $self->{_is_finished} = 1;
}

1;

__END__

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

=item * Mailing list

L<http://lists.swish-e.org/listinfo/users>

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

