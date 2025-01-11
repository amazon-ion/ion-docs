#!/usr/bin/env bash

# Tests this package
# Assumes that the `fusion` CLI is on our $PATH

set -o errexit  # Exit if any statement returns a non-true return value.
set -o nounset  # Exit if any uninitialized variable is used.
set -o pipefail # Exit if commands fail as part of a pipeline.
#set -o xtrace   # Print a trace of the commands being executed.

fusion() {
  ~/src/fusion-java/build/install/fusion/bin/fusion \
    --repositories ./ftst/repo:./fusion \
    "${@}"
}

runUnitTests() {
    local -a testfiles
    readarray -t testfiles < <(find ftst -name '*.test.fusion' -print)
    # This doesn't work, and I have no idea why:
    #find ftst -name '*.test.fusion' -print #| readarray -t testfiles

    for test in "${testfiles[@]}"
    do
        echo "----> $test"
        fusion load "$test"
    done
}

runConformanceTests() {
    local -a testfiles
    readarray -t testfiles < <(find ftst/conformance -name '*.ion' -print)

    for test in "${testfiles[@]}"
    do
        echo "----> $test"
        # TODO This should run in a namespace with only this dialect
        fusion require "/ion_model/testing/dsl" \; load "$test"
    done
}

runUnitTests
runConformanceTests
