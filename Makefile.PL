use strict;
use warnings;
use ExtUtils::MakeMaker;

my $MM_Version = $ExtUtils::MakeMaker::VERSION;

if ( $MM_Version =~ /_/ )    # dev version
{
    $MM_Version = eval $MM_Version;
    die $@ if ($@);
}

WriteMakefile(
    NAME          => 'SWISH::Prog::KSx',
    AUTHOR        => q{Peter Karman <karman at cpan dot org>},
    VERSION_FROM  => 'lib/SWISH/Prog/KSx.pm',
    ABSTRACT_FROM => 'lib/SWISH/Prog/KSx.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::More'    => 0,
        'KinoSearch'    => '0.30_09',    
        'SWISH::Prog'   => 0.44,         
        'SWISH::3'      => 0.04,         # mem leak fixes in >= 0.04
        'Sort::SQL'     => 0.06,
        'Search::Query::Dialect::KSx' => 0.06,
    },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'SWISH-Prog-KSx-* t/index.swish' },
    ( $MM_Version >= 6.48 ? ( MIN_PERL_VERSION => '5.8.3' ) : () ),
    ( $MM_Version >= 6.31 ? ( LICENSE          => 'perl' )  : () ),
    (   $MM_Version <= 6.44 ? ()
        :

            (
            META_MERGE => {
                resources => {
                    license  => 'http://dev.perl.org/licenses/',
                    homepage => 'http://dev.swish-e.org/wiki/perl',
                    bugtracker =>
                        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=SWISH-Prog-KSx',
                    repository =>
                        'http://svn.swish-e.org/perl/SWISH-Prog-KSx/',
                },
            }
            )
    ),
);
