# Ion 1.1 Semantics

This repository is a first crack at putting the operational semantics for Ion 1.1 templates into AsciiDoc.

## Building

The easiest way to build the spec is to use the included `Dockerfile`.  Assuming you have `docker` you can run the build
script in the project directory as follows:

```
$ ./build-docker.sh
```

The above script, when run for the first time, will build a docker image containing all of the dependencies in a Linux
container and then run a transient container with that image to build the PDF/HTML.  The arguments to this script are
the arguments to run `bundle exec rake`:

```
# build the spec
$ ./build-docker.sh spec:build

# clean-up
$ ./build-docker.sh spec:clean

# build the spec with watches to auto-rebuild on file change
$ ./build-docker.sh spec:watch
```