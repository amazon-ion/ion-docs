# Ion 1.1 Specification

This repository holds the draft proposal for Ion 1.1.

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
