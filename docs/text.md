---
redirect_from: "/text.html"
title: Ion Text Encoding
description: "An explanation of the Amazon Ion text encoding."
---

# [Docs][1]/ {{ page.title }}

A [value stream][2] in the text encoding must be a
valid sequence of Unicode code points in any of the three encoding forms
(i.e. UTF-8, UTF-16, or UTF-32).

## ANTLR Grammar {#grammar}

There is a text file of the [Ion Text ANTLR v4 Grammar][3], it is also reproduced below.

```antlr
// Ion Text 1.0 ANTLR v4 Grammar
//
// The following grammar does not encode all of the Ion semantics, in particular:
//
//   * Timestamps are syntactically defined but the rules of ISO 8601 need to be
//     applied (especially regarding day rules with months and leap years).
//   * Non $ion_1_0 version markers are not trapped (e.g. $ion_1_1, $ion_2_0)
//   * Edge cases around Unicode semantics:
//      - ANTLR specifies only four hex digit unicode escapes and on Java operates
//        on UTF-16 code units (this is a flaw in ANTLR).
//      - The grammar doesn't validate unpaired surrogate escapes in symbols or strings
//        (e.g. "\udc00")

grammar IonText;

// note that EOF is a concept for the grammar, technically Ion streams
// are infinite
top_level
    : (ws* top_level_value)* ws* value? EOF
    ;

top_level_value
    : annotation+ top_level_value
    | delimiting_entity
    // numeric literals (if followed by something), need to be followed by
    // whitespace or a token that is either quoted (e.g. string) or
    // starts with punctuation (e.g. clob, struct, list)
    | numeric_entity ws
    | numeric_entity quoted_annotation value
    | numeric_entity delimiting_entity
    // literals that are unquoted symbols or keywords have a similar requirement
    // as the numerics above, they have different productions because the
    // rules for numerics are the same in s-expressions, but keywords
    // have different rules between top-level and s-expressions.
    | keyword_entity ws
    | keyword_entity quoted_annotation value
    | keyword_entity keyword_delimiting_entity
    ;

// TODO let's make sure this terminology
// is consistent with our specification documents
value
    : annotation* entity
    ;

entity
    : numeric_entity
    | delimiting_entity
    | keyword_entity
    ;

delimiting_entity
    : quoted_text
    | SHORT_QUOTED_CLOB
    | LONG_QUOTED_CLOB
    | BLOB
    | list
    | sexp
    | struct
    ;

keyword_delimiting_entity
    : delimiting_entity
    | numeric_entity
    ;

keyword_entity
    : any_null
    | BOOL
    | SPECIAL_FLOAT
    | IDENTIFIER_SYMBOL
    // note that this is because we recognize the type names for null
    // they are ordinary symbols on their own
    | TYPE
    ;

numeric_entity
    : BIN_INTEGER
    | DEC_INTEGER
    | HEX_INTEGER
    | TIMESTAMP
    | FLOAT
    | DECIMAL
    ;

annotation
    : symbol ws* COLON COLON ws*
    ;

quoted_annotation
    : QUOTED_SYMBOL ws* COLON COLON ws*
    ;

list
    : L_BRACKET ws* value ws* (COMMA ws* value)* ws* (COMMA ws*)? R_BRACKET
    | L_BRACKET ws* R_BRACKET
    ;

sexp
    : L_PAREN (ws* sexp_value)* ws* value? R_PAREN
    ;

sexp_value
    : annotation+ sexp_value
    | sexp_delimiting_entity
    | operator
    // much like at the top level, numeric/identifiers/keywords
    // have similar delimiting rules
    | numeric_entity ws
    | numeric_entity quoted_annotation value
    | numeric_entity sexp_delimiting_entity
    | sexp_keyword_entity ws
    | sexp_keyword_entity quoted_annotation value
    | sexp_keyword_entity sexp_keyword_delimiting_entity
    | NULL ws
    | NULL quoted_annotation value
    | NULL sexp_null_delimiting_entity
    ;

sexp_delimiting_entity
    : delimiting_entity
    ;

sexp_keyword_delimiting_entity
    : sexp_delimiting_entity
    | numeric_entity
    | operator
    ;

sexp_null_delimiting_entity
    : delimiting_entity
    | NON_DOT_OPERATOR+
    ;

sexp_keyword_entity
    : typed_null
    | BOOL
    | SPECIAL_FLOAT
    | IDENTIFIER_SYMBOL
    // note that this is because we recognize the type names for null
    // they are ordinary symbols on their own
    | TYPE
    ;

operator
    : (DOT | NON_DOT_OPERATOR)+
    ;

struct
    : L_CURLY ws* field (ws* COMMA ws* field)* ws* (COMMA ws*)? R_CURLY
    | L_CURLY ws* R_CURLY
    ;

field
    : field_name ws* COLON ws* annotation* entity
    ;

any_null
    : NULL
    | typed_null
    ;

typed_null
    : NULL DOT NULL
    | NULL DOT TYPE
    ;

field_name
    : symbol
    | SHORT_QUOTED_STRING
    | (ws* LONG_QUOTED_STRING)+
    ;

quoted_text
    : QUOTED_SYMBOL
    | SHORT_QUOTED_STRING
    | (ws* LONG_QUOTED_STRING)+
    ;

symbol
    : IDENTIFIER_SYMBOL
    // note that this is because we recognize the type names for null
    // they are ordinary symbols on their own
    | TYPE
    | QUOTED_SYMBOL
    ;

ws
    : WHITESPACE
    | INLINE_COMMENT
    | BLOCK_COMMENT
    ;

//////////////////////////////////////////////////////////////////////////////
// Ion Punctuation
//////////////////////////////////////////////////////////////////////////////

L_BRACKET : '[';
R_BRACKET : ']';
L_PAREN   : '(';
R_PAREN   : ')';
L_CURLY   : '{';
R_CURLY   : '}';
COMMA     : ',';
COLON     : ':';
DOT       : '.';

NON_DOT_OPERATOR
    : [!#%&*+\-/;<=>?@^`|~]
    ;

//////////////////////////////////////////////////////////////////////////////
// Ion Whitespace / Comments
//////////////////////////////////////////////////////////////////////////////

WHITESPACE
    : WS+
    ;

INLINE_COMMENT
    : '//' .*? (NL | EOF)
    ;

BLOCK_COMMENT
    : '/*' .*? '*/'
    ;

//////////////////////////////////////////////////////////////////////////////
// Ion Null
//////////////////////////////////////////////////////////////////////////////

NULL
    : 'null'
    ;

TYPE
    : 'bool'
    | 'int'
    | 'float'
    | 'decimal'
    | 'timestamp'
    | 'symbol'
    | 'string'
    | 'clob'
    | 'blob'
    | 'list'
    | 'sexp'
    | 'struct'
    ;

//////////////////////////////////////////////////////////////////////////////
// Ion Bool
//////////////////////////////////////////////////////////////////////////////

BOOL
    : 'true'
    | 'false'
    ;

//////////////////////////////////////////////////////////////////////////////
// Ion Timestamp
//////////////////////////////////////////////////////////////////////////////

TIMESTAMP
    : DATE ('T' TIME?)?
    | YEAR '-' MONTH 'T'
    | YEAR 'T'
    ;

fragment
DATE
    : YEAR '-' MONTH '-' DAY
    ;

fragment
YEAR
    : '000'                     [1-9]
    | '00'            [1-9]     DEC_DIGIT
    | '0'   [1-9]     DEC_DIGIT DEC_DIGIT
    | [1-9] DEC_DIGIT DEC_DIGIT DEC_DIGIT
    ;

fragment
MONTH
    : '0' [1-9]
    | '1' [0-2]
    ;

fragment
DAY
    : '0'   [1-9]
    | [1-2] DEC_DIGIT
    | '3'   [0-1]
    ;

fragment
TIME
    : HOUR ':' MINUTE (':' SECOND)? OFFSET
    ;

fragment
OFFSET
    : 'Z'
    | PLUS_OR_MINUS HOUR ':' MINUTE
    ;

fragment
HOUR
    : [01] DEC_DIGIT
    | '2' [0-3]
    ;

fragment
MINUTE
    : [0-5] DEC_DIGIT
    ;

// note that W3C spec requires a digit after the '.'
fragment
SECOND
    : [0-5] DEC_DIGIT ('.' DEC_DIGIT+)?
    ;

//////////////////////////////////////////////////////////////////////////////
// Ion Int
//////////////////////////////////////////////////////////////////////////////

BIN_INTEGER
    : '-'? '0' [bB] BINARY_DIGIT (UNDERSCORE? BINARY_DIGIT)*
    ;

DEC_INTEGER
    : '-'? DEC_UNSIGNED_INTEGER
    ;

HEX_INTEGER
    : '-'? '0' [xX] HEX_DIGIT (UNDERSCORE? HEX_DIGIT)*
    ;

//////////////////////////////////////////////////////////////////////////////
// Ion Float
//////////////////////////////////////////////////////////////////////////////

SPECIAL_FLOAT
    : PLUS_OR_MINUS 'inf'
    | 'nan'
    ;

FLOAT
    : DEC_INTEGER DEC_FRAC? FLOAT_EXP
    ;

fragment
FLOAT_EXP
    : [Ee] PLUS_OR_MINUS? DEC_DIGIT+
    ;

//////////////////////////////////////////////////////////////////////////////
// Ion Decimal
//////////////////////////////////////////////////////////////////////////////

DECIMAL
    : DEC_INTEGER DEC_FRAC? DECIMAL_EXP?
    ;

fragment
DECIMAL_EXP
    : [Dd] PLUS_OR_MINUS? DEC_DIGIT+
    ;

//////////////////////////////////////////////////////////////////////////////
// Ion Symbol
//////////////////////////////////////////////////////////////////////////////

QUOTED_SYMBOL
    : SYMBOL_QUOTE SYMBOL_TEXT SYMBOL_QUOTE
    ;

fragment
SYMBOL_TEXT
    : (TEXT_ESCAPE | SYMBOL_TEXT_ALLOWED)*
    ;

// non-control Unicode and not single quote or backslash
fragment
SYMBOL_TEXT_ALLOWED
    : '\u0020'..'\u0026' // no C1 control characters and no U+0027 single quote
    | '\u0028'..'\u005B' // no U+005C backslash
    | '\u005D'..'\uFFFF' // should be up to U+10FFFF
    | WS_NOT_NL
    ;

IDENTIFIER_SYMBOL
    : [$_a-zA-Z] ([$_a-zA-Z] | DEC_DIGIT)*
    ;

//////////////////////////////////////////////////////////////////////////////
// Ion String
//////////////////////////////////////////////////////////////////////////////

SHORT_QUOTED_STRING
    : SHORT_QUOTE STRING_SHORT_TEXT SHORT_QUOTE
    ;

LONG_QUOTED_STRING
    : LONG_QUOTE STRING_LONG_TEXT LONG_QUOTE
    ;


fragment
STRING_SHORT_TEXT
    : (TEXT_ESCAPE | STRING_SHORT_TEXT_ALLOWED)*
    ;

fragment
STRING_LONG_TEXT
    : (TEXT_ESCAPE | STRING_LONG_TEXT_ALLOWED)*?
    ;

// non-control Unicode and not double quote or backslash
fragment
STRING_SHORT_TEXT_ALLOWED
    : '\u0020'..'\u0021' // no C1 control characters and no U+0022 double quote
    | '\u0023'..'\u005B' // no U+005C backslash
    | '\u005D'..'\uFFFF' // FIXME should be up to U+10FFFF
    | WS_NOT_NL
    ;

// non-control Unicode (newlines are OK)
fragment
STRING_LONG_TEXT_ALLOWED
    : '\u0020'..'\u005B' // no C1 control characters and no U+005C blackslash
    | '\u005D'..'\uFFFF' // FIXME should be up to U+10FFFF
    | WS
    ;

fragment
TEXT_ESCAPE
    : COMMON_ESCAPE | HEX_ESCAPE | UNICODE_ESCAPE
    ;

//////////////////////////////////////////////////////////////////////////////
// Ion CLOB
//////////////////////////////////////////////////////////////////////////////

SHORT_QUOTED_CLOB
    : LOB_START WS* SHORT_QUOTE CLOB_SHORT_TEXT SHORT_QUOTE WS* LOB_END
    ;

LONG_QUOTED_CLOB
    : LOB_START (WS* LONG_QUOTE CLOB_LONG_TEXT*? LONG_QUOTE)+ WS* LOB_END
    ;

fragment
CLOB_SHORT_TEXT
    : (CLOB_ESCAPE | CLOB_SHORT_TEXT_ALLOWED)*
    ;

fragment
CLOB_LONG_TEXT
    : CLOB_LONG_TEXT_NO_QUOTE
    | '\'' CLOB_LONG_TEXT_NO_QUOTE
    | '\'\'' CLOB_LONG_TEXT_NO_QUOTE
    ;

fragment
CLOB_LONG_TEXT_NO_QUOTE
    : (CLOB_ESCAPE | CLOB_LONG_TEXT_ALLOWED)
    ;

// non-control ASCII and not double quote or backslash
fragment
CLOB_SHORT_TEXT_ALLOWED
    : '\u0020'..'\u0021' // no U+0022 double quote
    | '\u0023'..'\u005B' // no U+005C backslash
    | '\u005D'..'\u007F'
    | WS_NOT_NL
    ;

// non-control ASCII (newlines are OK)
fragment
CLOB_LONG_TEXT_ALLOWED
    : '\u0020'..'\u0026' // no U+0027 single quote
    | '\u0028'..'\u005B' // no U+005C blackslash
    | '\u005D'..'\u007F'
    | WS
    ;

fragment
CLOB_ESCAPE
    : COMMON_ESCAPE | HEX_ESCAPE
    ;

//////////////////////////////////////////////////////////////////////////////
// Ion BLOB
//////////////////////////////////////////////////////////////////////////////

BLOB
    : LOB_START (BASE_64_QUARTET | WS)* BASE_64_PAD? WS* LOB_END
    ;

fragment
BASE_64_PAD
    : BASE_64_PAD1
    | BASE_64_PAD2
    ;

fragment
BASE_64_QUARTET
    : BASE_64_CHAR WS* BASE_64_CHAR WS* BASE_64_CHAR WS* BASE_64_CHAR
    ;

fragment
BASE_64_PAD1
    : BASE_64_CHAR WS* BASE_64_CHAR WS* BASE_64_CHAR WS* '='
    ;

fragment
BASE_64_PAD2
    : BASE_64_CHAR WS* BASE_64_CHAR WS* '=' WS* '='
    ;

fragment
BASE_64_CHAR
    : [0-9a-zA-Z+/]
    ;

//////////////////////////////////////////////////////////////////////////////
// Common Lexer Primitives
//////////////////////////////////////////////////////////////////////////////

fragment LOB_START    : '{{';
fragment LOB_END      : '}}';
fragment SYMBOL_QUOTE : '\'';
fragment SHORT_QUOTE  : '"';
fragment LONG_QUOTE   : '\'\'\'';

// Ion does not allow leading zeros for base-10 numbers
fragment
DEC_UNSIGNED_INTEGER
    : '0'
    | [1-9] (UNDERSCORE? DEC_DIGIT)*
    ;

fragment
DEC_FRAC
    : '.'
    | '.' DEC_DIGIT (UNDERSCORE? DEC_DIGIT)*
    ;

fragment
DEC_DIGIT
    : [0-9]
    ;

fragment
HEX_DIGIT
    : [0-9a-fA-F]
    ;

fragment
BINARY_DIGIT
    : [01]
    ;

fragment
PLUS_OR_MINUS
    : [+\-]
    ;

fragment
COMMON_ESCAPE
    : '\\' COMMON_ESCAPE_CODE
    ;

fragment
COMMON_ESCAPE_CODE
    : 'a'
    | 'b'
    | 't'
    | 'n'
    | 'f'
    | 'r'
    | 'v'
    | '?'
    | '0'
    | '\''
    | '"'
    | '/'
    | '\\'
    | NL
    ;

fragment
HEX_ESCAPE
    : '\\x' HEX_DIGIT HEX_DIGIT
    ;

fragment
UNICODE_ESCAPE
    : '\\u'     HEX_DIGIT_QUARTET
    | '\\U000'  HEX_DIGIT_QUARTET HEX_DIGIT 
    | '\\U0010' HEX_DIGIT_QUARTET
    ;

fragment
HEX_DIGIT_QUARTET
    : HEX_DIGIT HEX_DIGIT HEX_DIGIT HEX_DIGIT
    ;

fragment
WS
    : WS_NOT_NL
    | '\u000A' // line feed
    | '\u000D' // carriage return
    ;

fragment
NL
    : '\u000D\u000A'  // carriage return + line feed
    | '\u000D'        // carriage return
    | '\u000A'        // line feed
    ;

fragment
WS_NOT_NL
    : '\u0009' // tab
    | '\u000B' // vertical tab
    | '\u000C' // form feed
    | '\u0020' // space
    ;

fragment
UNDERSCORE
    : '_'
    ;
```

<!-- references -->
[1]: {{ site.baseurl }}/docs.html
[2]: glossary.html#value_stream
[3]: {{ site.baseurl }}/grammar/IonText.g4.txt