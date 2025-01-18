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
    if [[ ! -v _FUSION_EXE ]]
    then
        if [[ -v FUSION_HOME ]]
        then
            _FUSION_EXE=$FUSION_HOME/bin/fusion
            if [[ ! -x $_FUSION_EXE ]]
            then
                echo "ERROR: Invalid FUSION_HOME=$FUSION_HOME"
                exit 1
            fi
        elif hash fusion 2>/dev/null
        then
            # It's on the PATH
            _FUSION_EXE=fusion
        else
            # shellcheck disable=SC2016
            echo 'ERROR: FUSION_HOME is not defined and `fusion` is not on PATH'
            exit 1
        fi
    fi
}


runFusion() {
    locateFusion
    "$_FUSION_EXE" \
        --repositories ./ftst/repo:./fusion \
        "${@}"
}

locateIonDocs() {
    if [[ -z ${ION_DOCS:-} ]]
    then
      if [[ -d ../ion-docs ]]
      then
        ION_DOCS=../ion-docs
      elif [[ -d ~/src/ion-docs ]]
      then
        ION_DOCS=~/src/ion-docs
      else
        fail echo "Unable to locate ion-docs directory."
      fi
    elif [[ ! -d $ION_DOCS ]]
    then
      fail echo "ION_DOCS isn't a directory: $ION_DOCS"
    fi
}

locate() {
    locateFusion
    locateIonDocs

    echo "Using Fusion CLI at $(which "$_FUSION_EXE")"
    echo "Updating ion-docs at $ION_DOCS"
}


###############################################################################
# Testing the model

runUnitTests() {
    local -a testfiles
    readarray -t testfiles < <(find ftst -name '*.test.fusion' -print)
    # This doesn't work, and I have no idea why:
    #find ftst -name '*.test.fusion' -print #| readarray -t testfiles

    for test in "${testfiles[@]}"
    do
        echo "----> $test"
        runFusion load "$test"
    done
}

runConformanceTests() {
    local -a testfiles
    readarray -t testfiles < <(find ftst/conformance -name '*.ion' -print)

    for test in "${testfiles[@]}"
    do
        echo "----> $test"
        # TODO This should run in a namespace with only this dialect
        runFusion require "/ion_model/testing/dsl" \; load "$test"
    done
}

test() {
    runUnitTests
    runConformanceTests
}


###############################################################################
# Generating the document content

generate() {
    locateIonDocs

    outdir="$ION_DOCS"/src/tex

    echo "Generating LaTeX into $outdir"
    runFusion --repositories ./fusion load gentex.fusion > "$outdir"/ion-model.tex

    echo
    echo "Rebuilding the PDF"
    (
        cd "$ION_DOCS"
        ./build-docker.sh build/Semantics.pdf
    )
}

target=${1:-test}
case $target in
    locate)     locate;;
    test)       test;;
    generate)   generate;;
    *)          fail echo "Unknown target $target";;
esac
