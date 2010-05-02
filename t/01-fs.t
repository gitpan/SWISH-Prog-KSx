#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 29;
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

ok( my $searcher
        = SWISH::Prog::KSx::Searcher->new( invindex => 't/index.swish', ),
    "new searcher"
);

ok( my $results = $searcher->search('test'), "search()" );

#diag( dump $results );

is( $results->hits, 1, "1 hit" );

ok( my $result = $results->next, "next result" );

is( $result->uri, 't/test.html', 'get uri' );

is( $result->title, "test html doc", "get title" );

diag( $result->score );

# test limit
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

# test sort
ok( my $results3 = $searcher->search(
        'some', { order => 'swishdocpath asc swishrank desc' }
    ),
    "search()"
);
is( $results3->hits, 2, "2 hits" );
my @results;
while ( my $result3 = $results3->next ) {
    push @results, $result3->swishdocpath;
}
is_deeply( \@results, [qw( t/test.html t/test.xml )], "results sorted ok" );

# test wildcard query
ok( my $results4 = $searcher->search('S?M*'), "search()" );
is( $results4->hits, 2, "2 hits" );

ok( my $results5 = $searcher->search('running*'),
    "search stemmable wildcard" );
is( $results5->hits, 1, "1 hit" );

ok( my $results6 = $searcher->search(qq/"text here"~4/), "search proximity" );
is( $results6->hits, 1, "1 hit" );

ok( my $results7 = $searcher->search(qq/(som* or word*) and here/),
    "compound wildcard" );
is( $results7->hits, 2, "2 hits for compound wildcard query" );

# break the query parser
eval { my $results7 = $searcher->search(qq/"out touch~2/); };
ok( $@, "query parser catches poor syntax" );

END {
    unless ( $ENV{PERL_DEBUG} ) {
        $invindex->path->rmtree;
    }
}
