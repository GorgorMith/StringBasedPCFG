#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use StringBasedPCFG::StringBasedPCFG;
use Set::Scalar;

our $no_probabilities = 0;
my $help = 0;

my $Usage = <<"EOT";
Usage: $0 [OPTIONS] FILE

Extract rules from a treebank.

FILE should contain a treebank. Tabs separate token from parse bits. Example:
    Fred	(S (NP (NNP ('Fred')))
    convinced	(VP (VBD ('convinced'))
    the (NP (DT ('the'))
    man	(NN ('man')))))

OPTIONS
    -n, --no-probabilities
        Do not print the probabilities of the rules.
    -h, --help
        Print this help message.
EOT

GetOptions(
    "no-probabilities|n" => \$no_probabilities,
    "help|h"             => \$help
) or die "$Usage";

if ( $help or scalar @ARGV == 0 ) {
    print "$Usage" and exit;
}

sub main {

    # Args:
    # 1. A string holding the name of a file containing a treebank.
    my $filename = shift;
    my @trees    = StringBasedPCFG::getTrees($filename);
    my ( $rules, $startSymbol ) =
      StringBasedPCFG::getRulesFromTreeArray(@trees);

    if ($no_probabilities) {

        # Without weights.
        printRules( $rules, $startSymbol );
    }
    else {

        # With weights.
        my %nonTerminalFrequencies =
          StringBasedPCFG::getNonTerminalFrequencies(@$rules);

        my %weightedRules =
          StringBasedPCFG::getWeights( \%nonTerminalFrequencies, @$rules );

        StringBasedPCFG::printWeightedRules( \%weightedRules, $startSymbol );
    }
}

sub printRules {

    # Print an array of rules with the starting rules at the top.
    # Args:
    # 1. A reference to an array of rules.
    # 2. The start symbol.
    my $ruleArray   = shift;
    my $startSymbol = shift;

    my $rules = Set::Scalar->new(@$ruleArray);
    my $startingRules =
      Set::Scalar->new( grep { /^\Q$startSymbol\E\s+/ } @$rules );
    my $nonStartingRules = $rules - $startingRules;

    print join( "\n", sort @$startingRules ),    "\n";
    print join( "\n", sort @$nonStartingRules ), "\n";
}

main @ARGV;
