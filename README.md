# StringBasedPCFG

This is a simple module for inducing probabilistic context-free grammars
(PCFGs) from a treebank. It also provides features to evaluate a tree
against another one.

All its features rely on string parsing. That's where the module got its name.

Tree syntax
===========

Traditionally, parse trees are written in lisp-like syntax. A tree for the
sentence "The dog bites John" might look like this (The tagset used here is
the [Penn Treebank tagset](https://www.ling.upenn.edu/courses/Fall_2003/ling001/penn_treebank_pos.html)):
`(S (NP (DT 'The')(NN 'dog'))(VP (VBD 'bites')(NP (NNP 'John'))))`

The module StringBasedPCFG natively uses a slighlty different syntax in that
it puts parentheses around the leaves as well. The above tree would look like
that:
`(S (NP (DT ('The'))(NN ('dog')))(VP (VBD ('bites'))(NP (NNP ('John')))))`

This problem will be addressed in the future.

Inducing a PCFG
===============

The script `extract_rules.pl` provides an interface for inducing a PCFG.
To induce a PCFG call `extract_rules.pl <treebank>`.
If you only care about the rules and don't care about their probabilities,
you can also call `extract_rules.pl --no-probabilities <treebank>` to omit the
probabilities.

Evaluating a tree
=================

To evaluate your grammar, you can use the script `evaluateTrees.pl`. Pass the
trees as strings like so:
`extract_rules.pl <auto-annotated-tree> <gold-annotated-tree>`
