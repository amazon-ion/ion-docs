#!/bin/bash
set -e

# The download URL below assumes a snapshot tag, since the project doesn't
# yet publish regular releases.
SNAPSHOT_NAME=fusion-0.38a1-SNAPSHOT


cd "${BOOTSTRAP_DIR:?}"

curl -L -o fusion.zip https://github.com/ion-fusion/fusion-java/releases/download/snapshot/$SNAPSHOT_NAME.zip
unzip fusion.zip

# Move to a fixed path, so invoking code isn't coupled to the specific version.
mv "$SNAPSHOT_NAME" fusion-java
