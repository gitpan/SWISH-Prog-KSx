use Test::More tests => 17;
use strict;
use Data::Dump qw( dump );

use_ok('SWISH::Prog');
use_ok('SWISH::Prog::KSx::InvIndex');
use_ok('SWISH::Prog::KSx::Searcher');

ok( my $invindex = SWISH::Prog::KSx::InvIndex->new(
        clobber => 0,                 # KS handles this
        path    => 't/index.swish',
    ),
    "new invindex"
);

ok( my $program = SWISH::Prog->new(
        invindex   => $invindex,
        aggregator => 'fs',
        indexer    => 'ks',
        config     => 't/config.xml',

        #verbose    => 1,
        #debug      => 1,
    ),
    "new program"
);

# skip the index dir every time
# the '1' arg indicates to append the value, not replace.
$program->config->FileRules( 'dirname is index.swish', 1 );
$program->config->FileRules( 'filename is config.xml', 1 );

ok( $program->index('t/'), "run program" );

is( $program->count, 2, "indexed test docs" );

ok( my $searcher = SWISH::Prog::KSx::Searcher->new(
        invindex => 't/index.swish',
    ),
    "new searcher"
);

ok( my $results = $searcher->search('test'), "search()" );

#diag( dump $results );

is( $results->hits, 1, "1 hit" );

ok( my $result = $results->next, "next result" );

is( $result->uri, 't/test.html', 'get uri' );

is( $result->title, "test html doc", "get title" );

diag( $result->score );

# test some search() features
# NOTE these only available in KS version > 0.30072

SKIP: {

    if ( $KinoSearch::VERSION <= 0.30072 and !$ENV{TEST_LIMIT_FEATURE} ) {
        skip
            "limit feature avaiable in KinoSearch version > 0.30072 -- you have $KinoSearch::VERSION",
            4;
    }

    ok( my $results2 = $searcher->search(
            'some', { limit => [ [qw( date 2010-01-01 2010-12-31 )] ] }
        ),
        "search()"
    );
    is( $results2->hits, 1, "1 hit" );
    while ( my $result2 = $results2->next ) {
        diag( $result2->uri );
        is( $result2->uri,   't/test.xml',  'get uri' );
        is( $result2->title, "ima xml doc", "get title" );
        diag( $result2->score );
    }

}

END {
    unless ( $ENV{PERL_DEBUG} ) {
        $invindex->path->rmtree;
    }
}
