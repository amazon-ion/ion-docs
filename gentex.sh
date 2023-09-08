#!/bin/bash

set -o errexit  # Exit if any statement returns a non-true return value.
set -o nounset  # Exit if any uninitialized variable is used.
set -o pipefail # Exit if commands fail as part of a pipeline.
#set -o xtrace   # Print a trace of the commands being executed.


if [[ -z ${ION_DOCS:-} ]];
then
  if [[ -d ../ion-docs ]];
  then
    ION_DOCS=../ion-docs
  elif [[ -d ~/src/ion-docs ]];
  then
    ION_DOCS=~/src/ion-docs
  else
    echo >@2 "Unable to locate ion-docs directory."
    exit 1
  fi
elif [[ ! -d $ION_DOCS ]];
then
  echo >@2 "ION_DOCS isn't a directory: $ION_DOCS"
fi

outdir="$ION_DOCS"/src/tex

echo "Generating LaTeX into $outdir"

fusion --repositories ./fusion load gentex.fusion > "$outdir"/ion-model.tex


echo
echo "Rebuilding the PDF"

cd "$ION_DOCS"
./build-docker.sh build/Semantics.pdf
