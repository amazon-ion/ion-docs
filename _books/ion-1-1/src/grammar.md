# Grammar

This chapter presents Ion 1.1's _domain grammar_, by which we mean the grammar of the domain 
of values that drive Ion's encoding features.

We use a BNF-like notation for describing various syntactic parts of a document, including Ion data structures. 
In such cases, the BNF should be interpreted loosely to accommodate Ion-isms like commas, whitespace, and unconstrained ordering of struct fields.

For brevity, the following components are not explicitly defined in this grammar:
* `value` - any Ion value literal
* `unannotated-identifier-symbol` - an unannotated "identifier symbol" (as defined in the specification)
* `unannotated-uint` - an unannotated integer greater than or equal to zero

### Documents
```bnf
document           ::= ivm segment*

ivm                ::= '$ion_1_1'

any-value-encoding ::= value | macro-invocation | tagless-element-list | tagless-element-sexp

segment            ::= any-value-encoding* directive?

directive          ::= ivm | encoding-directive
```

### Directives
```bnf
encoding-directive    ::= '(:$ion ' any-directive-content ')'

any-directive-content ::= set-symbols-content | add-symbols-content | set-macros-content | add-macros-content
                        | use-content | module-content | import-content | encoding-content

set-symbols-content   ::= 'set_symbols' symbol-text*
add-symbols-content   ::= 'add_symbols' symbol-text*
set-macros-content    ::= 'set_macros' macro-definition*
add-macros-content    ::= 'add_macros' macro-definition*
use-content           ::= 'use' catalog-key
module-content        ::= 'module' module-name macro-table? symbol-table?
import-content        ::= 'import' module-name catalog-key
encoding-content      ::= 'encoding' module-name*
```

### Modules
```bnf
catalog-key             ::= catalog-name catalog-version?

catalog-name            ::= string

catalog-version         ::= unannotated-uint

module-name             ::= unannotated-identifier-symbol

symbol-table            ::= '(symbols' symbol-table-entry* ')'

symbol-table-entry      ::= module-name | symbol-list

symbol-list             ::= '[' symbol-text* ']'

symbol-text             ::= symbol | string

macro-table             ::= '(macros' macro-table-entry* ')'

macro-table-entry       ::= macro-definition-in-module | module-name
```

### Macro references
```bnf
qualified-macro-ref     ::= module-name '::' macro-ref

macro-ref               ::= macro-name | macro-addr

macro-name              ::= unannotated-identifier-symbol

macro-addr              ::= unannotated-uint

any-macro-ref-encoding  ::= macro-ref | qualified-macro-ref
```

### Macro definitions
```bnf
macro-name-declaration     ::= macro-name | 'null'
macro-definition           ::= '(' macro-definition-contents ')'
macro-definition-in-module ::= '(macro' macro-definition-contents ')'
macro-definition-contents  ::= macro-name-declaration value-with-placeholders ; This prohibits "identity" macros

value-or-placeholder       ::= value-with-placeholders | placeholder
list-with-placeholders     ::= '[' value-or-placeholder* ']' ; Note: for brevity, this grammar avoids comma handling
sexp-with-placeholders     ::= '(' value-or-placeholder* ')'
field-value-or-placeholder ::= symbol-text ':' value-or-placeholder
struct-with-placeholders   ::= '{' field-value-or-placeholder* }
value-with-placeholders    ::= value | list-with-placeholders | sexp-with-placeholders | struct-with-placeholders

primitive-encoding-type    ::= 'int' | 'int8' |  'int16' |  'int32' |  'int64'
                             | 'uint' | 'uint8' | 'uint16' | 'uint32' | 'uint64'
                             | 'float16' | 'float32' | 'float64'
                             | 'small_decimal'
                             | 'timestamp_day' | 'timestamp_min' | 'timestamp_s'
                             | 'timestamp_ms' | 'timestamp_us' | 'timestamp_ns'
                             | 'symbol'

primitive-encoding-opcode  ::= '0x60' | '0x61' | '0x62' | '0x64' | '0x68'
                             | '0xE0' | '0xE1' | '0xE2' | '0xE4' | '0xE8'
                             | '0x6B' | '0x6C' | '0x6D'
                             | '0x70'
                             | '0x82' | '0x83' | '0x84'
                             | '0x85' | '0x86' | '0x87'
                             | '0xEE'

primitive-type-identifier  ::= primitive-encoding-type | primitive-encoding-opcode
primitive-type-marker      ::= '{#' primitive-type-identifier '}'
macro-type-marker          ::= '{:' any-macro-ref-encoding '}'
any-type-marker-encoding   ::= primitive-type-marker | macro-type-marker

placeholder                ::= tagged-placeholder | tagged-placeholder-default | tagless-placeholder
tagged-placeholder         ::= '(:?)'
tagged-placeholder-default ::= '(:? ' value ')'
tagless-placeholder        ::= '(:? ' primitive-type-marker ')'

tagless-element-list       ::= '[' any-type-marker-encoding value* ']'
tagless-element-sexp       ::= '(' any-type-marker-encoding value* ')'
```

### Macro invocations

```bnf
no-argument             ::= '(:)'
macro-argument          ::= any-value-encoding | no-argument
macro-invocation        ::= '(:' any-macro-ref-encoding macro-argument* ')'
```
