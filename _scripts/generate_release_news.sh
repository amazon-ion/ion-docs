#!/usr/bin/env bash

# Loops through a whitespace delimited list of Ion repositories, and generates
# a news item for the latest release of each repository if a news item doesn't
# already exist for that release.
#
# Any news items that are generated will automatically be staged for commit.
# The user or workflow that is running the script is responsible for committing
# and pushing any changes.
#
# When running locally, if any news items are generated, an auto-generated
# commit message will be echoed to stdout. When running in GitHub Actions, the
# number of changes and the generated commit message will be exported as outputs
# of the workflow step--'changes' and 'generated_commit_message' respectively.
#
# This script does not generate news items for releases marked as a pre-release
# version.

# TODO: See if github actions can use the github cli to automatically list all Ion repositories.
# readonly REPO_NAMES="$(gh api teams/2323876/repos --jq '.[] | select(.visibility == "public") | .name')"

# This should be kept up-to-date with all PUBLIC Ion repositories.
readonly REPO_NAMES="\
ion-c
ion-cli
ion-docs
ion-dotnet
ion-eclipse-plugin
ion-element-kotlin
ion-go
ion-hash
ion-hash-dotnet
ion-hash-go
ion-hash-java
ion-hash-js
ion-hash-python
ion-hash-test
ion-hash-test-driver
ion-hive-serde
ion-intellij-plugin
ion-java
ion-java-benchmark-cli
ion-java-path-extraction
ion-js
ion-kotlin-builder
ion-python
ion-rust
ion-schema
ion-schema-kotlin
ion-schema-rust
"

commit_msg_body=""

for repo_name in $REPO_NAMES; do
  # Groups the logs in GitHub Actions to make them nicer to read.
  [[ $GITHUB_ACTIONS ]] && echo "::group::$repo_name"

  echo "Checking for releases in $repo_name"
  release="$(gh release view -R "amazon-ion/$repo_name" --json body,createdAt,tagName)"
  if [[ -z "$release" ]]; then
    [[ $GITHUB_ACTIONS ]] && echo "::endgroup::"
    continue
  fi

  release_date="$(jq -r '.createdAt' <<< "$release" | cut -d'T' -f1)"
  tag="$(jq -r '.tagName' <<< "$release")"
  version="$(cut -d'v' -f2 <<< "$tag")"
  news_item_file_path="_posts/$release_date-$repo_name-$(sed 's/\./_/g' <<< "$version")-released.md"

  # NOTE: If we decide that we want to include the release notes in the news item, we need to remove
  # the '\r' characters from the release body. i.e.:
  # release_notes = $(jq -r '.body' <<< "$release" | sed -e 's/\r//g')

  echo "Found release $tag"

  # If file already exists, then we already have a new item for this release.
  if [[ -f $news_item_file_path ]]; then
    echo 'News already exists for this release.'
  else
    title_case_repo_name="$(sed -e "s/\-/ /g" <<< "$repo_name" | awk '{for (i=1;i <= NF;i++) {sub(".",substr(toupper($i),1,1),$i)} print}')"

    # Collapses any repeated newlines down to a single newline
    sed -e '/./b' -e :n -e 'N;s/\n$//;tn' <<< "\
---
layout: news_item
title: \"$title_case_repo_name $version Released\"
date: $release_date
categories: news $repo_name
---

$title_case_repo_name $version is now available.

| [Release Notes $tag](https://github.com/amazon-ion/$repo_name/releases/tag/$tag) | [$title_case_repo_name](https://github.com/amazon-ion/$repo_name) |
" >> "$news_item_file_path"

    git add "$news_item_file_path"
    echo "Generated '$news_item_file_path'"
    commit_msg_body=$(printf '%s\n%s' "$commit_msg_body" "* $repo_name $tag")

    # Update the data for the table on the libraries page
    libraries=$(< _data/libraries.json)
    jq "map(select(.name == \"$repo_name\") += \
       { latest_release_version: \"$version\", latest_release_date: \"$release_date\"} )" \
       <<< $libraries > _data/libraries.json
  fi

  [[ $GITHUB_ACTIONS ]] && echo "::endgroup::"
done

readonly NUM_NEW_POSTS=$(git status -s -uno | grep -c _posts/)
echo "Generated $NUM_NEW_POSTS news items."
if [[ $NUM_NEW_POSTS -ne 0 ]]; then
  git add _data/libraries.json
  readonly GENERATED_NEWS_COMMIT_MESSAGE="$(printf 'Adds news posts for %s releases\n%s\n' "$NUM_NEW_POSTS" "$commit_msg_body")"
  if [[ $GITHUB_ACTIONS ]]; then
    echo "::set-output name=changes::$NUM_NEW_POSTS"
    # Need to escape newlines to prevent output from being truncated
    echo "::set-output name=generated_commit_message::${GENERATED_NEWS_COMMIT_MESSAGE//$'\n'/'%0A'}"
  else
    echo "$GENERATED_NEWS_COMMIT_MESSAGE"
  fi
fi
