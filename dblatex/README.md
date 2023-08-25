# dblatex Configuration and Implementation Notes

AsciiDoctor's support for "STEM" content (that is, math notation) is patchy
with respect to producing multiple output formats.  It supports three STEM
libraries — [MathJax][], [AsciiDoctor-Mathematical][ADM], and [AsciiMath Gem][] —
each with its own limitations and notation support, especially for LaTeX.
Further, while Mathematical supports the HTML, DocBook XML, and direct-PDF 
backends, that project is weakly supported and layers atop obsolete and
unsupported tools.

To achieve better support for math notation, and a more robust toolchain, we can
abandon AsciiDoctor's direct-PDF rendering and instead generate PDF from the
DocBook XML.  This file documents use of `dblatex` to achieve that.

At present, we don't invoke `dblatex` directly from our Rakefile; we route
through `xmlto` as recommended by the AsciiDoctor documentation.  As `xmlto` is
primarily (if not purely) a shell script, it's unclear whether this provides any
benefit over using `dblatex` directly.


## How It Works

Here's the call chain, as far as I understand it:

  * The `:docbook` target invokes `asciidoctor -b docbook` to transform the
    `.adoc` file set into a DocBook `.xml` file in the `build` directory. 
  * The `:pdf` target invokes `xmlto --with-dblatex` passing the `.xml` file.
    * `xmlto` has a lot of XSLT logic, but it appears to be unused with the
        `dblatex` backend.
    * `xmlto` invokes `dblatex` passing the `.xml` file.
      * `dblatex` creates a temporary directory to hold intermediate files. 
        This can be annoying since it disappears with the Docker container.
      * `dblatex` uses XSLT (and a lot of style) to transform the XML into
        "raw TeX" format using the `.rtex` extension.
      * `dblatex` runs a custom Python-based `texclean` process to turn the 
        `.rtex` into a valid `.tex` file.  This does [many things][dbl-process]
        but most notably (and problematically) it performs certain Unicode
        character transformations and escapes inside listing blocks.
      * `dblatex` then generates PDF from the `.tex` using the `pdflatex`
        engine.
      * `dblatex` copies the PDF into our `build` directory.

For more information, see:
  * The [`dblatex` Publishing Principles][dbl-process] documentation.
  * [DocBook to LaTeX Publishing][dbl-pdf], the dblatex user manual.


## Opportunities for Improvement

* We use Unicode ellipses characters `…` intentionally, to avoid ambiguity with 
  the `...` token of the macro language.  But the `…` are being rendered as
  three periods in PDF, returning the ambiguity.
* The PDF renders single-quotes `'` as an angled quote, which looks strange.
* Using `xmlto` may be bringing more complexity than its worth since it's easier
  to invoke `dblatex` directly.  Perhaps it will be more useful if we 
  generate HTML from DocBook, instead of directly from AsciiDoc.
* Besides `pdftex`, `dblatex` also supports the `xelatex` to generate the PDP.
  Research on the TeX StackExchange suggests that this is a more modern engine
  that may have better Unicode support and thus require less customization.


## Deep Dive on `dblatex` Unicode Handling

It took a lot of digging and experimentation to get our document rendered 
properly.  Here are notes on what I learned.


### Configuration Options

`dblatex` gives three distinct configurations for Unicode handling.
As it turns out, none are sufficient for our needs.

#### (No setting)

Results in a LaTeX document encoding non-Latin-1 code points using XML entity
references like `&#x250f;`.

The document prologue is configured as follows:

```
\usepackage[T1]{fontenc}
\usepackage[latin1]{inputenc}
```

#### `latex.unicode.use=1`

"Asks for including the unicode package (initially provided by Passivetex) in
order to handle many of the unicode characters in a latin1 encoded document."

The LaTeX document uses entity references, as with the default configuration,
and adds this to the prologue:

```
\usepackage{unicode}
```

#### `latex.encoding=utf8`

"Produces a document encoded in UTF8, that is compiled in UTF8. It requires to
have the `ucs` package installed."

This replaces the default the prologue above with:

```
\usepackage[T2A,T2D,T1]{fontenc}
\usepackage{ucs}
\usepackage[utf8x]{inputenc}
...
\lstset{inputencoding=utf8x, extendedchars=true}
```

This setup has drawbacks:

* The `T2A` font encoding requires installing the `texlive-lang-cyrillic`
  package into the Docker image.

    
### Changing to `utf8` Input Encoding

Currently, our binary-encoding diagrams are DocBook `screen` elements using the
"box drawing characters".  Regardless of the configuration above, the standard
`dblatex`/`pdftex` chain doesn't know how to render them.
When using UTF-8 encoding, this surfaces as:
```
Package ucs Error: Unknown Unicode character 9484 = U+250C,
```

Canonical support for these characters is provided by the `pmboxdraw` package, 
but experimentation shows that it works with `[utf8]{inputenc}`, but not the
`[utf8x]{inputenc}` format produced by `dblatex`.

Not coincidentally, a number StackExchange answers dis-recommend `utf8x`.
Notably, in https://tex.stackexchange.com/questions/464393 a 2018 comment says:
> it is generally better to avoid `\usepackage[utf8x]{inputenc}\usepackage{ucs}`
> unless you know you need that version and use the standard `utf8` inputenc
> option (which is enabled by default in recent releases, so you don't need
> inputenc at all)
Also in 2019 at https://latex.org/forum/viewtopic.php?t=6635:
> I recommend to avoid the `utf8x` option since the `ucs` package to which it
> belongs is not really supported anymore and breaks a lot of packages,
> e.g. `csquotes`.

For this reason, we customize the XLS templates (see `dblatex/ion.xsl`),
replacing the standard prologue content above to instead use `[utf8]{inputenc}`.

Even still, not all Unicode characters are recognized by default, and I wasn't
able to find a package providing them, so the ones we need are defined
explicitly in `dblatex/ion.sty`.


### Unicode in Listings

dblatex uses the (apparently well-established) `listings` package to represent
"verbatim" DocBook elements like `screen` and `programlisting`.
Quite non-obviously, this package doesn't integrate with `inputenc` and must be
configured independently.  This means that a number of Unicode characters in
listings need to be explicitly defined in `ion.sty`.


### dblatex Escaping Problems

Making things worse, dblatex is currently fairly buggy in its handling of
Unicode in listings.  Its `texclean` step (transforming `.rtex` to `.tex`)
forcibly escapes any non-Latin1 characters therein, even though that's no longer
necessary, and that escaping is itself broken.

The escapes are clearly intended to be `<:` and `:>` but they appear in the
`.tex` document as `b'<:'` and `b':>'`, perhaps due to incompatibility with
Python 3.  To work around this, the [dblatex post-processing script][dbl-postprocess]
`dblatex/postprocess.sh` corrects those so that the listings package handles
them as intended.

As of 2023-08, I note the following additional issues:
* Comments say that "listings cannot handle unicode characters greater than 255"
  but that's clearly untrue since our box-characters are making it through to
  the PDF when the `inputenc` is `utf8` or `utf8x`.
  https://salsa.debian.org/debian/dblatex/-/blob/master/lib/dbtexmf/dblatex/rawverb.py#L32
* The requested encoding isn't passed from the `RawUtfParser` to the
  `RawLatexParser`.
  https://salsa.debian.org/debian/dblatex/-/blob/master/lib/dbtexmf/dblatex/rawparse.py#L83
* If a listing contains both unicode characters and bold/italic content, then
  the resulting `lstlisting` has different `escapeinside` clauses in two 
  parameter sets, and the second seems to be ignored. This leaves dangling 
  escapes like `<b>` in the output.


### Notes on dblatex XSLT

#### Listings

DocBook `programlisting|screen|literallayout` are transformed into LaTex here:
https://salsa.debian.org/debian/dblatex/-/blob/master/xsl/verbatim.xsl#L215

The options to `lstlisting` are computed here:
https://salsa.debian.org/debian/dblatex/-/blob/master/xsl/verbatim.xsl#L306

Escapes are generated by `listing-delim` template:
https://salsa.debian.org/debian/dblatex/-/blob/master/xsl/verbatim.xsl#L428

But that's only invoked when `$co-tagin` is defined;
https://salsa.debian.org/debian/dblatex/-/blob/master/xsl/verbatim.xsl#L382

That happens when there's callouts <co> ...
https://salsa.debian.org/debian/dblatex/-/blob/master/xsl/verbatim.xsl#L285
... or "some elements needing escaping"
https://salsa.debian.org/debian/dblatex/-/blob/master/xsl/verbatim.xsl#L278

That in turn is based on whether content "probed" with the
`latex.programlisting` mode produces anything:
https://salsa.debian.org/debian/dblatex/-/blob/master/xsl/verbatim.xsl#L279

That happens many places:
https://salsa.debian.org/search?group_id=2&repository_ref=master&search=latex.programlisting&search_code=true&project_id=43520

It's a documented extension point:
https://dblatex.sourceforge.net/doc/manual/sec-verbatim.html


[ADM]:             https://docs.asciidoctor.org/asciidoctor/latest/stem/mathematical/
[AsciiMath Gem]:   https://docs.asciidoctor.org/asciidoctor/latest/stem/asciimath-gem/
[MathJax]:         https://docs.asciidoctor.org/asciidoctor/latest/stem/mathjax/
[dbl-pdf]:         https://sources.debian.org/src/dblatex/0.3.12py3-1/docs/manual.pdf
[dbl-postprocess]: https://dblatex.sourceforge.net/doc/manual/sec-texpost.html
[dbl-process]:     https://dblatex.sourceforge.net/doc/manual/ch01s05.html
