#!/usr/bin/env perl

use strict;
use warnings;

use StringBasedPCFG::StringBasedPCFG;

sub main {
    my $lispTree =
'(S (NP (NNP Fred)) (VP (VBD convinced) (NP (NP (NP (DT the) (NN man)) (PP (IN with) (NP (DT a) (NN telescope)))) (PP (IN from) (NP (NNP London))))))';
    my $tree = StringBasedPCFG::getTreeFromLispTree($lispTree);
    print "$lispTree\n";
    print "$tree\n";
}

main @ARGV;
