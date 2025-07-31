<!-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. -->
<!-- SPDX-License-Identifier: Apache-2.0 -->

# A Denotational Semantic Model for Amazon Ion

This package contains a denotational semantic model of Ion's expansion layer:
the processing that happens after the byte-stream parser computes an abstract
syntax tree. The model serves two main purposes:

* It can be printed in traditional lambda-calculus notation,
acting as a formal specification.
* It can be executed against the Ion conformance suite,
acting as a reference implementation.

Everything is built using the [Ion Fusion](https://ion-fusion.dev) language.

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

Within `ftst` directory:

  * `dsl` is the test suite for the denotational semantics modeling library.
  * `ion` and `ion11` contain lower-level unit tests for the Ion model.


## Conformance Tests

The official Ion conformance suite is in the [ion-tests GitHub repository][gh-tests]

To make these files available to the Fusion runtime, our build logic a copy of,
or symlink to, the `ion-tests` source code at the
root of this package.  This is an atypical approach, since one should
usually only depend on output artifacts, not source code.  But here we know
that the source code _is_ the output, and by linking directly to the source
a developer can edit the test cases and re-test the model without having to
build the test package.

Additional conformance tests reside in this package under `ftst/conformance`.
These are in the process of migrating to GitHub and are intended to be
incrementally removed as that progresses.


## Printing the Model

The semantic model can be "pretty-printed" in the form of a LaTeX file that's
consumed by the narrative document.  In general, when the model changes you'll
likely make corresponding prose changes at the same time.

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


[gh-tests]: https://github.com/amazon-ion/ion-tests/


## Building

The easiest way to build the spec is to use the included `Dockerfile`.  Assuming you have `finch` or `docker` on your
`PATH`, you can run the build script in the project directory as follows:

```
$ ./build-docker.sh
```

The above script, when run for the first time, will build a docker image containing all of the dependencies in a Linux
container and then run a transient container with that image to build the PDF/HTML.  The arguments to this script are
the arguments to run `bundle exec rake`:

```
# build the spec in all formats
$ ./build-docker.sh build

# clean-up
$ ./build-docker.sh clean

# build the spec with watches to auto-rebuild on file change
$ ./build-docker.sh watch
```

## Debugging

Running `build-docker.sh -s` opens a shell in a new container.
Once there, you can run `rake` directly, for example `rake pdf`.


## Development

The source text should be hard wrapped at 120 characters.  One way to do this is to use the [Rewrap][rewrap] extension
in [VS Code][vscode].

Reviewing changes of these docs can be rough in raw diffs/pull-requests in Github.  One way to work around this is to
create Word documents using [`pandoc`][pandoc]:

```
$ pandoc -f docbook -t docx -o NEW.docx ./build/Ion-Specification.xml
```

Assuming you have an `OLD.docx` you can use Word's [comparison][word-compare] feature to create a cromulent diff.

Attempts to use tools like `diffpdf` and `pandiff` have not yielded great results in the past.

[rewrap]: https://marketplace.visualstudio.com/items?itemName=stkb.rewrap
[vscode]: https://code.visualstudio.com/
[pandoc]: https://pandoc.org/
[word-compare]: https://support.microsoft.com/en-us/office/compare-and-merge-two-versions-of-a-document-f5059749-a797-4db7-a8fb-b3b27eb8b87e
