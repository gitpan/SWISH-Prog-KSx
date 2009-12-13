use Test::More tests => 13;
use strict;

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
        config   => 't/test.conf',
    ),
    "new searcher"
);

ok( my $results = $searcher->search('test'), "search()" );

is( $results->hits, 1, "1 hit" );

ok( my $result = $results->next, "next result" );

is( $result->uri, 't/test.html', 'get uri' );

is( $result->title, "test html doc", "get title" );

diag( $result->score );

END {
    unless ( $ENV{PERL_DEBUG} ) {
        $invindex->path->rmtree;
    }
}
