# Symbol tokens

In Ion text, symbols are represented in three ways:

* __Quoted symbol__: a sequence of zero or more characters between
  single-quotes, *e.g.*, `'hello'`, `'a symbol'`, `'123'`, `''`.
  This representation can denote any symbol text.
* __Identifier__: an unquoted sequence of one or more ASCII letters, digits,
  or the characters `$` (dollar sign) or `_` (underscore), not starting with
  a digit and not including the keywords `null`, `nan`, `true`, and `false`.
* __Operator__: an unquoted sequence of one or more of the following nineteen
  ASCII characters: `` !#%&*+-./;<=>?@^`|~ ``
  Operators can only be used as (direct) elements of an S-expression.
  In any other context those characters require single-quotes.

A subset of identifiers have special meaning:

* __Symbol Identifier__: an identifier that starts with `$` (dollar sign)
  followed by one or more digits. These identifiers directly represent the
  symbol's integer symbol ID, not the symbol's text.
  This form is not typically visible to users, but they should be aware of
  the reserved notation so they don't attempt to use it for other purposes.