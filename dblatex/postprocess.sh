#!/bin/bash

# dblatex post-processing script to correct mangled escapes in listing blocks.
# https://dblatex.sourceforge.net/doc/manual/sec-texpost.htm

# This script is called by dblatex from within the temporary directory.
here=$(dirname "$0")
file="$1"


# If sed returns 1, don't pass it through; that has special meaning to dblatex.

sed --in-place=.BAK --file="$here/postprocess.sed" "$file" || exit 2

# We don't need to keep this if the cleanup succeeded.
rm "$file".BAK
