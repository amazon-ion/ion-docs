#!/usr/bin/env bash

## Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
## SPDX-License-Identifier: Apache-2.0

# Tests this package

set -o errexit  # Exit if any statement returns a non-true return value.
set -o nounset  # Exit if any uninitialized variable is used.
set -o pipefail # Exit if commands fail as part of a pipeline.
#set -o xtrace   # Print a trace of the commands being executed.


fail() {
    {
        printf "ERROR: "
        "${@}"
    } 1>&2
    exit 1
}


###############################################################################
# Locating dependencies

locateFusion() {
    if [[ -z ${_FUSION_EXE:-} ]]
    then
        if [[ -n ${FUSION_HOME:-} ]]
        then
            _FUSION_EXE=$FUSION_HOME/bin/fusion
            if [[ ! -x $_FUSION_EXE ]]
            then
                fail echo "Invalid FUSION_HOME=$FUSION_HOME"
            fi
        elif hash fusion 2>/dev/null
        then
            # It's on the PATH
            _FUSION_EXE=fusion
        else
            # shellcheck disable=SC2016
            fail echo 'FUSION_HOME is not defined and `fusion` is not on PATH'
        fi
    fi
}


runFusion() {
    locateFusion
    "$_FUSION_EXE" \
        --repositories ./ftst/repo:./fusion \
        "${@}"
}


locate() {
    locateFusion

    echo "Using Fusion CLI at $(which "$_FUSION_EXE")"
}


###############################################################################
# Testing the model

runUnitTests() {
    local test
    while IFS= read -r test
    do
        echo "----> $test"
        runFusion load "$test"
    done < <(find ftst -name '*.test.fusion' -print)
}

runConformanceTests() {
    local dir=$1

    local test
    while IFS= read -r test
    do
        echo "----> $test"
        # TODO This should run in a namespace with only this dialect
        runFusion require "/ion_model/testing/dsl" \; load "$test"
    done < <(find "$dir"/conformance -name '*.ion' -print)
}

test() {
    if [[ ! -d ./ion-tests/catalog ]]
    then
        fail echo "ion-tests not present. Add a symlink to it in this directory."
    fi

    runUnitTests
    runConformanceTests ftst
    runConformanceTests ion-tests
}


###############################################################################
# Generating the document content

generate() {
    echo "Generating LaTeX for the semantic model"
    mkdir -p build/tex
    runFusion --repositories ./fusion load gentex.fusion > build/tex/ion-model.tex
}

target=${1:-test}
case $target in
    locate)     locate;;
    test)       test;;
    generate)   generate;;
    *)          fail echo "Unknown target $target";;
esac
