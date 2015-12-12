#!/usr/bin/env perl -w
package StringBasedPCFG;

use strict;
use Exporter qw(import);
use Set::Scalar;

our $VERSION   = 0.10;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
  getTrees
  getRulesFromTreeArray
  getRulesFromTree
  getDaughterTrees
  count
  getNonTerminalFrequencies
  getWeights
  printWeightedRules
  readWeightedRules
  getProbabilityOfTree
  getLabelledBrackets
  getFirstLabel
  getLeavesInTree
  formatLabelledBrackets
  formatBracket
  getTPFPFN
  evaluateBrackets
  calculateEvaluation
);

sub getTrees {

    # Get an array of trees from a file containing a treebank.
    # Args:
    # 1. A string holding the name of a file containing a treebank.
    my $filename = shift;
    open my $fh, '<', $filename or die "Could not read file: $filename ($!)";
    my @trees;
    my $curTree = '';
    for my $line (<$fh>) {
        if ( $line =~ /^\S+\t(.*)\n$/ ) {

            # Append tree part to current tree.
            $curTree .= $1;
        }
        else {

            # Push current tree on tree array.
            push @trees, $curTree unless $curTree eq '';
            $curTree = '';
        }
    }
    push @trees, $curTree unless $curTree eq '';
    close($fh);
    return @trees;
}

sub getRulesFromTreeArray {

    # Get an array of phrase structure rules from an array of trees.
    # The array can hold one rule multiple times.
    # Args:
    # 1. An array of trees.
    my @trees = @_;
    my @rules;
    my $startSymbols = Set::Scalar->new;

    # Get Rules.
    for my $tree (@trees) {
        my ($treeRules, $startSymbol) = getRulesFromTree($tree);
        push @rules, @$treeRules;
        $startSymbols->insert($startSymbol)
    }

    if ($startSymbols->size > 1) {
        # Only one start symbol is allowed.
        die "More than one start symbol found: $startSymbols\n";
    }

    my $startSymbol = @$startSymbols[0];
    return (\@rules, $startSymbol);
}

sub getRulesFromTree {

    # Get an array of phrase structure rules and a start symbol from a tree.
    # The array can hold one rule multiple times.
    # Args:
    # 1. A string holding a tree.
    my $tree = shift;
    my @rules;
    my $startSymbol = '';

    # Remove whitespace from tree.
    $tree =~ s/\s+//g;

    if ( $tree =~ /^\(([^)]+)\)$/ ) {

       # Break recursion if the tree only contains an expression in parentheses.
        return (\@rules, $startSymbol);
    }
    elsif ( $tree =~ /^\(([^)(]+)(\(.*\))\)$/ ) {

        # Get rules recursively.
        #my ( $left, $remainder ) = ( $1, $2 );
        my $left    = $1;
        $startSymbol = $left;
        my @phrases = getDaughterTrees($tree);
        my @rightParts;
        for my $phrase (@phrases) {
            $phrase =~ /^\(([^)(]+).*$/;
            push @rightParts, $1;
            my ($phraseRules, $phraseStartSymbol) = getRulesFromTree($phrase);
            push @rules, @$phraseRules;
        }
        my $right = join ' ', @rightParts;
        my $rule = "$left -> $right";
        push @rules, $rule;
    }
    else {
        die "Could not read tree: $tree";
    }
    return (\@rules, $startSymbol);
}

sub getDaughterTrees {

    # Get an array of daughter trees from a tree.
    # Args:
    # 1. A string holding a tree; cannot contain any whitespace
    my $parent = $_[0];
    my @daughters;
    my $openedPars = 0;
    my $closedPars = 0;
    my $start      = 0;

    # Get the tree which contains the daughters.
    $parent =~ /^\(([^)(]+)(\(.*\))\)$/;
    my $daughterString = $2;

    for ( my $i = 0 ; $i < length($daughterString) ; ++$i ) {
        if ( substr( $daughterString, $i, 1 ) eq '(' ) {
            ++$openedPars;
        }
        elsif ( substr( $daughterString, $i, 1 ) eq ')' ) {
            ++$closedPars;
            if ( $openedPars == $closedPars and $openedPars != 0 ) {
                push @daughters,
                  substr( $daughterString, $start, $i - $start + 1 );
                $openedPars = 0;
                $closedPars = 0;
                $start      = $i + 1;
            }
        }
    }
    return @daughters;
}

sub count {

    # Count all lines of @array that match $regex.
    # Args:
    # 1. A reference to a regex
    # 2. An array
    my $regex = shift;
    my @array = @_;
    my $count = scalar grep { /$regex/ } @array;
    return $count;
}

sub getNonTerminalFrequencies {

    # Get a hash mapping non-terminal symbols to their frequencies of
    # appearing on the left side of a phrase structure rule.
    # Args:
    # 1. An array strings holding phrase structure rules.
    my @rules = @_;
    my @nonTerminals = map { local $_ = $_; s/^([^ ]+) .*$/$1/; $_ } @rules;
    my %nonTerminalFrequencies = map { $_ => 0 } @nonTerminals;
    foreach my $key ( keys %nonTerminalFrequencies ) {

        # Escape regex meta-characters for using $key in a regex.
        my $quotedKey = quotemeta($key);
        $nonTerminalFrequencies{$key} =
          count( qr/^$quotedKey$/, @nonTerminals );
    }
    return %nonTerminalFrequencies;
}

sub getWeights {

    # Get the probability weights for phrase structure rules.
    # Args:
    # 1. A reference to a hash mapping non-terminal symbols to frequencies.
    # 2. An array strings holding phrase structure rules.
    my $nonTerminalFrequencies = shift;
    my @rules                  = @_;
    my %weightedRules;
    foreach my $rule (@rules) {
        if ( not exists $weightedRules{$rule} ) {
            $rule =~ /^([^ ]+) .*$/;
            my $nonTerminal      = $1;
            my $quotedRule       = quotemeta($rule);
            my $ruleCount        = count( $quotedRule, @rules );
            my $nonTerminalCount = $nonTerminalFrequencies->{$nonTerminal};
            $weightedRules{$rule} = $ruleCount / $nonTerminalCount;
        }
    }
    return %weightedRules;
}

sub printWeightedRules {

    # Print a hash mapping rules to their probability weights.
    # Print the starting rules at the top.
    # Args:
    # 1. A reference to a hash mapping rules to their probability weights.
    # 2. The start symbol.
    my $weightedRules = shift;
    my $startSymbol = shift;
    my @startingRules;
    my @nonStartingRules;

    foreach my $rule ( sort keys %$weightedRules ) {
        my $weight = $weightedRules->{$rule};
        my $ruleString = "$rule\t$weight";

        if ($rule =~ /^\Q$startSymbol\E\s+/) {
            push @startingRules, $ruleString;
        }
        else {
            push @nonStartingRules, $ruleString;
        }
    }
    print join("\n", @startingRules), "\n";
    print join("\n", @nonStartingRules), "\n";
}

sub readWeightedRules {

    # Read a grammar from a file.
    # Args:
    # 1. A string holding the name of a file containing a pcfg.
    my $filename = shift;
    my %weightedRules;
    open my $fh, '<', $filename or die "Could not read file: $filename ($!)";
    foreach my $line (<$fh>) {
        $line =~ /(.*)\t(.*)\n/;

        #my ($rule, $probability) = split "\t", $line;
        my ( $rule, $probability ) = ( $1, $2 );
        if ( not exists $weightedRules{$rule} ) {
            $weightedRules{$rule} = $probability;
        }
    }
    return %weightedRules;
}

sub getProbabilityOfTree {

    # Get the probability of a tree under a given grammar.
    # Args:
    # 1. A string holding a tree.
    # 2. A reference to a hash mapping phrase structure rules to probabilities.
    my $tree        = shift;
    my $grammarRef  = shift;
    my @usedRules   = getRulesFromTree($tree);
    my $probability = 1.0;

    #$probability *= $grammarRef->{$_} for @usedRules
    #    or die "Rule not in grammar: $_";
    foreach my $rule (@usedRules) {
        $probability *= $grammarRef->{$rule};
    }
    return $probability;
}

sub getLabelledBrackets {

    # Get an array of labelled brackets from a tree. The labelled brackets are
    # arrays containing a label and numbers denoting start and end posiion.
    # Args:
    # 1. A string holding a tree.
    # 2. The number of leaves preceding the given tree. Default: 0.
    #
    # TODO: Redesign this subroutine.
    my $tree = shift;
    my $start;
    $start = shift or $start = 0;
    my $leaves = $start;

    # Remove whitespace from tree.
    $tree =~ s/\s+//g;

    my @labelledBrackets;
    my $treeLength = length($tree);
    my $label      = getFirstLabel($tree);

    my $gotDaughters = 0;
    my $openedPars   = 1;
    my $closedPars   = 0;
    for ( my $i = 1 ; $i < $treeLength ; ++$i ) {
        if ( substr( $tree, $i, 1 ) eq '(' ) {
            ++$openedPars;
            if ( substr( $tree, $i, $treeLength - $i ) =~ /^\([^(]+\)/ ) {

                # A leaf has been found.
                ++$leaves;
            }
            elsif ( not $gotDaughters ) {

                # Push the brackets in the daughter trees on the array.
                my $leavesInDaughters = 0;
                for my $daughter ( getDaughterTrees($tree) ) {
                    push @labelledBrackets,
                      getLabelledBrackets( $daughter,
                        $leaves + $leavesInDaughters );
                    $leavesInDaughters += leavesInTree($daughter);
                }
                $gotDaughters = 1;
            }
        }
        elsif ( substr( $tree, $i, 1 ) eq ')' ) {
            ++$closedPars;
            if ( $openedPars == $closedPars and $openedPars != 0 ) {

                # All the ingredients for a bracket are now known.
                # Push the found bracket on the tree.
                my $end = $leaves;

                #print "$start $$leaves $end\n";
                my @bracket = ( $label, $start, $end );

                #print join("\t", @bracket), "\n";
                push @labelledBrackets, \@bracket;
            }
        }
    }
    return @labelledBrackets;
}

sub getFirstLabel {

    # Get the first label in a tree fragment.
    # Args:
    # 1. A string holding a tree
    my $tree = shift;
    $tree =~ /^\(([^(]+)\(/
      or die "Could not find first label in tree fragment: $tree";
    my $label = $1;
    return $label;
}

sub leavesInTree {

    # Count the leaves in a tree.
    # Args:
    # 1. A string holding a tree
    my $tree   = shift;
    my $leaves = 0;
    ++$leaves while ( $tree =~ /\([^(]+\)/g );
    return $leaves;
}

#sub cropRightParentheses {
#
#    # Remove superfluous parentheses from the end of a tree.
#    # Args:
#    # 1. A string holding a tree.
#    my $tree       = shift;
#    my $closedPars = 0;
#    ++$closedPars while ( $tree =~ /\)/g );
#    my $openedPars = 0;
#    ++$openedPars while ( $tree =~ /\(/g );
#    my $diff = $closedPars - $openedPars;
#    if ( $diff > 0 ) {
#
#        if ( $tree =~ /\)\){$diff}$/ ) {
#            $tree = substr( $tree, 0, length($tree) - $diff );
#        }
#        else {
#            die "Cannot fix tree by cropping right parentheses: $tree";
#        }
#    }
#    return $tree;
#}

sub formatLabelledBrackets {

    # Format an array of labelled brackets and return a string.
    # Args:
    # 1. An array of references to labelled brackets.
    my @labelledBrackets = @_;
    my @lines            = map { formatBracket(@$_) } @labelledBrackets;
    my $formatted        = join( "\n", @lines ) . "\n";
    return $formatted;
}

sub formatBracket {
    return join( "\t", @_ );
}

sub getTPFPFN {

    # Evaluate an array of labelled brackets against another one.
    # Return number of true positives, false positives and true negatives.
    # Args:
    # 1. A reference to an array of labelled brackets. (Gold)
    # 2. A reference to an array of labelled brackets. (Auto)

    my $autoRef = shift;
    my $goldRef = shift;

    # Turn the brackets from arrays of arrays into sets of strings.
    my $auto = Set::Scalar->new( map { formatBracket(@$_) } @$autoRef );
    my $gold = Set::Scalar->new( map { formatBracket(@$_) } @$goldRef );
    my ( $TP, $FP, $FN );
    $TP = $auto * $gold;    # intersection
    $FP = $auto - $gold;    # difference
    $FN = $gold - $auto;    # difference
    return ( $TP->size, $FP->size, $FN->size );
}

sub evaluateBrackets {

    # Evaluate an array of labelled brackets against another one.
    # Return precision recall and f-measure.
    # Args:
    # 1. A reference to an array of labelled brackets. (Gold)
    # 2. A reference to an array of labelled brackets. (Auto)

    my $autoRef = shift;
    my $goldRef = shift;

    my ( $TP, $FP, $FN ) = getTPFPFN( $autoRef, $goldRef );
    return calculateEvaluation( $TP, $FP, $FN );
}

sub calculateEvaluation {

    # Calculate precision, recall and f-measure from the number of true
    # positives, false positives and false negatives.
    # Args:
    # 1. True positives.
    # 2. False positives.
    # 3. False negatives.

    my $TP = shift;
    my $FP = shift;
    my $FN = shift;

    my $precision = $TP / ( $FP + $TP );
    my $recall    = $TP / ( $FN + $TP );
    my $fMeasure = 2 * $precision * $recall / ( $precision + $recall );
    return ( $precision, $recall, $fMeasure );
}

1;
