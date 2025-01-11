# IonSemanticModel

This package contains a denotational semantic model of Ion's expansion layer:
the processing that happens after the byte-stream parser computes an abstract
syntax tree. The model serves two main purposes:

* It can be printed in traditional lambda-calculus notation,
acting as a formal specification.
* It can be executed against the Ion conformance suite,
acting as a reference implementation.

Except for some Java code to run the tests via JUnit, everything is built in
Fusion.

The key Fusion modules are:

  * `/fusion/src/fusioncontrib/denotation` is a library implementing a DSL
for writing and executing denotational semantic models.
  * `/fusion/src/fusioncontrib/denotation/printing` is a library for pretty
printing Fusion code and data.
  * `/fusion/src/ion_model/model` is the Ion model itself.
  * `/fusion/src/ion_model/testing` holds an implementation of the Ion
conformance DSL, used to test the model.


## Unit Tests

The semantic model DSL, the printer, and some low-level aspects of the Ion 
model are tested using by the `*.test.fusion` files under the `ftst` directory.
These are scripts following the normal Fusion testing approach.
They are executed by a dynamic JUnit5 test suite
in [the `FusionScriptTests` class](src/test/java/FusionScriptTests.java).

Within `ftst` directory:

  * `dsl` is the test suite for the denotational semantics modeling library.
  * `ion` and `ion11` contain lower-level unit tests for the Ion model.


## Conformance Tests

The official Ion conformance suite is in [the ion-tests GitHub repository][gh-tests]


To make these files available to the Fusion runtime, our build logic has a 
pre-test target that creates a symlink to the `Ion-tests` source code at the
root of this package.  This is an atypical approach, since one should
usually only depend on output artifacts, not source code.  But here we know
that the source code _is_ the output, and by linking directly to the source
a developer can edit the test cases and re-test the model without having to
build the test package.

Additional conformance tests reside in this package under `ftst/conformance`.
These are in the process of migrating to GitHub and are intended to be
incrementally removed as that progresses.

Both sets of conformance tests are executed by a dynamic JUnit5 test suite
in [the `ConformanceTests` class](src/test/java/ConformanceTests.java).


## Printing the Model

The semantic model can be "pretty-printed" in the form of a LaTeX file that's
consumed by [the `ion-docs` repository][gh-docs] as part of the corresponding
narrative document.  This is not automated: the LaTeX output of this package
is manually committed into the document repostory.  (In general, you'll likely
make corresponding prose changes at the same time.)

To update the narrative document:

  

  * Clone `ion-docs` as a sibling directory of this package.
    * Alternatively, you can clone it into `~/src/ion-docs`.
    * Alternatively, set the shell-environment variable `ION_DOCS` to the
      location of your clone.
  * In this directory, run the `generate` target.
    That will update the LaTex at `ion-docs/src/tex/ion-model.tex` and then
    rebuild the PDF.
  * If things look good, commit the modified file(s) in `ion-docs`.

At present, the narrative only covers Ion 1.0 while this model has a large
volume of additional functions covering Ion 1.1.  This won't prevent the
document from rendering, and the additional content will only appear in the
appendix.  Some work should be done to improve the pretty-printing, rendering
of function names, and so on.  We could also benefit from some partitioning
of the model into subsections in the appendix.


[gh-docs]:  https://github.com/amazon-ion/ion-docs/
[gh-tests]: https://github.com/amazon-ion/ion-tests/
[br-tests]: code:Ion-tests/trees/ion-tests-1.x
