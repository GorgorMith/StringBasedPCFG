#!/usr/bin/env perl

use strict;
use warnings;

use StringBasedPCFG::StringBasedPCFG;

sub main {
    my $tree     = shift;
    my @brackets = StringBasedPCFG::getLabelledBrackets($tree);
    print StringBasedPCFG::formatLabelledBrackets(@brackets);
}

main @ARGV;
