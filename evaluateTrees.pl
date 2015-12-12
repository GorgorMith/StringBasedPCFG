#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use StringBasedPCFG::StringBasedPCFG;

our $cardinalities  = 0;
our $auto_lisp_tree = 0;
our $gold_lisp_tree = 0;
our $verbose        = 0;
my $help = 0;

my $Usage = <<"EOT";
Usage: $0 [OPTIONS] AUTO GOLD

Compare an auto-annotated tree to a gold-annotated tree. Print three
    evaluation measures: precision, recall and F-Measure.

AUTO and GOLD should be trees in somewhat lisp-like syntax.
    Whitespace like spaces or newlines is permitted. Example:
        (S (NP (NNP ('Fred'))) (VP (VBD ('convinced')) (NP (NNP ('John')))))

OPTIONS
    -h, --help
        Print this help message.
    -c, --cardinalities
        Don't print evaluation measures. Instead, print the number of
            true positives, false positives and false negatives.
    -a, --auto-lisp-tree
        The auto tree is in truly lisp-like syntax and without quotes. Example:
            (S (NP (NNP Fred)) (VP (VBD convinced) (NP (NNP John))))
    -g, --gold-lisp-tree
        The gold tree is in truly lisp-like syntax and without quotes. Example:
            (S (NP (NNP Fred)) (VP (VBD convinced) (NP (NNP John))))
    -v, --verbose
        Print evaluation measures as well as the cardinalities.
EOT

GetOptions(
    "auto-lisp-tree|a" => \$auto_lisp_tree,
    "gold-lisp-tree|g" => \$gold_lisp_tree,
    "cardinalities|c"  => \$cardinalities,
    "verbose|v"        => \$verbose,
    "help|h"           => \$help
) or die "$Usage";

if ( $help or scalar @ARGV == 0 ) {
    print "$Usage" and exit;
}

sub main {
    my $tree1 = shift;
    my $tree2 = shift;

    if ($auto_lisp_tree) {
        $tree1 = StringBasedPCFG::getTreeFromLispTree($tree1);
    }
    if ($gold_lisp_tree) {
        $tree2 = StringBasedPCFG::getTreeFromLispTree($tree2);
    }

    my @brackets1 = StringBasedPCFG::getLabelledBrackets($tree1);
    my @brackets2 = StringBasedPCFG::getLabelledBrackets($tree2);

    if ($verbose) {
        my ( $TP, $FP, $FN ) =
          StringBasedPCFG::getTPFPFN( \@brackets1, \@brackets2 );
        my ( $precision, $recall, $fMeasure ) =
          StringBasedPCFG::calculateEvaluation( \@brackets1, \@brackets2 );
        print "True Positives\t$TP\n";
        print "False Positives\t$FP\n";
        print "False Negatives\t$FN\n";
        print sprintf( "Precision\t%.3f\n", $precision );
        print sprintf( "Recall\t%.3f\n",    $recall );
        print sprintf( "F-Measure\t%.3f\n", $fMeasure );
    }
    elsif ( $cardinalities and not $verbose ) {
        my ( $TP, $FP, $FN ) =
          StringBasedPCFG::getTPFPFN( \@brackets1, \@brackets2 );
        print "True Positives\t$TP\n";
        print "False Positives\t$FP\n";
        print "False Negatives\t$FN\n";
    }
    else {
        my ( $precision, $recall, $fMeasure ) =
          StringBasedPCFG::evaluateBrackets( \@brackets1, \@brackets2 );
        print sprintf( "Precision: %.3f\n", $precision );
        print sprintf( "Recall: %.3f\n",    $recall );
        print sprintf( "F-Measure: %.3f\n", $fMeasure );
    }
}

main @ARGV;
