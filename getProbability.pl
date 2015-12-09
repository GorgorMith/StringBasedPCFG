#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use StringBasedPCFG::StringBasedPCFG;

my $help  = 0;
my $Usage = <<"EOT";

Usage: $0 [OPTIONS] TREE GRAMMAR

Print the probability of a tree under a specific grammar.

TREE should be a file containing a tree in lisp-like syntax. Whitespace like
    spaces or newlines is permitted. Example:
        (S (NP (NNP ('Fred'))) (VP (VBD ('convinced')) (NP (NNP ('John')))))

GRAMMAR should be a file containing a probabilistic context-free grammar.
    Tabs separate rules from probabilities. Example:
        S -> IN SBAR	0.166666666666667
        S -> NP VP	0.833333333333333
        SBAR -> NP VP	1
        VBD -> 'claimed'	0.166666666666667
        VBD -> 'convinced'	0.166666666666667

OPTIONS
    -h, --help
        Print this help message.
EOT

GetOptions( "help|h" => \$help )
  or die "$Usage";

if ($help) {
    print "$Usage" and exit;
}

sub main {
    my ( $treeFile, $grammarFile ) = @_;
    my $tree = '';
    open my $fh, "<", $treeFile or die "Could not read file: $treeFile ($!)";
    {
        local $/;
        $tree = <$fh>;
    }
    close $fh;

    my %weightedRules = StringBasedPCFG::readWeightedRules($grammarFile);
    my $probability = StringBasedPCFG::getProbabilityOfTree( $tree, \%weightedRules );
    print $probability, "\n";
}

main @ARGV;
