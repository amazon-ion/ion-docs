# Grammar

This chapter presents Ion 1.1's _domain grammar_, by which we mean the grammar of the domain 
of values that drive Ion's encoding features.

We use a BNF-like notation for describing various syntactic parts of a document, including Ion data structures. 
In such cases, the BNF should be interpreted loosely to accommodate Ion-isms like commas and unconstrained ordering of struct fields.

### Documents
```bnf
document           ::= ivm? segment*

ivm                ::= '$ion_1_0' | '$ion_1_1'

segment            ::= value* directive?

directive          ::= ivm 
                     | encoding-directive 
                     | symtab-directive 

symtab-directive   ::=  local-symbol-table     ; As per the Ion 1.0 specification¹

encoding-directive ::= '$ion_encoding::(' module-body ')'
```

&nbsp;&nbsp;&nbsp;&nbsp;¹[Symbols – Local Symbol Tables](https://amazon-ion.github.io/ion-docs/docs/symbols.html#local-symbol-tables).

### Modules
```bnf
module-body             ::= import* inner-module* symbol-table? macro-table?

shared-module           ::= '$ion_shared_module::' ivm '::(' catalog-key module-body ')'

import                  ::= '(import ' module-name catalog-key ')'

catalog-key             ::= catalog-name catalog-version?

catalog-name            ::= string

catalog-version         ::= unannotated-uint                   ; must be positive

inner-module            ::= '(module' module-name module-body ')'

module-name             ::= unannotated-identifier-symbol

symbol-table            ::= '(symbol_table' symbol-table-entry* ')'

symbol-table-entry      ::= module-name | symbol-list

symbol-list             ::= '[' symbol-text* ']'

symbol-text             ::= symbol | string

macro-table             ::= '(macro_table' macro-table-entry* ')'

macro-table-entry       ::= macro-definition
                          | macro-export
                          | module-name

macro-export            ::= '(export' qualified-macro-ref macro-name-declaration? ')'
```
### Macro references
```bnf
qualified-macro-ref     ::= module-name '::' macro-ref

macro-ref               ::= macro-name | macro-addr

qualified-macro-name    ::= module-name '::' macro-name

macro-name              ::= unannotated-identifier-symbol

macro-addr              ::= unannotated-uint 
```

### Macro definitions
```bnf
macro-definition        ::= '(macro' macro-name-declaration signature tdl-expression ')'

macro-name-declaration  ::= macro-name | 'null'

signature               ::= '(' parameter* ')'

parameter               ::= parameter-encoding? parameter-name parameter-cardinality?

parameter-encoding      ::= (primitive-encoding-type | macro-name | qualified-macro-name)'::'

primitive-encoding-type ::= 'uint8' | 'uint16' | 'uint32' | 'uint64'
                          |  'int8' |  'int16' |  'int32' |  'int64'
                          | 'float16' | 'float32' | 'float64'
                          | 'flex_int' | 'flex_uint' 
                          | 'flex_sym' | 'flex_string'

parameter-name          ::= unannotated-identifier-symbol

parameter-cardinality   ::= '!' | '*' | '?' | '+'

tdl-expression          ::= operation | variable-expansion | ion-scalar | ion-container

operation               ::= macro-invocation | special-form

variable-expansion      ::= '(%' variable-name ')'

variable-name           ::= unannotated-identifier-symbol

macro-invocation        ::= '(.' macro-ref macro-arg* ')'

special-form            ::= '(.' '$ion::'?  special-form-name tdl-expression* ')'

special-form-name       ::= 'for' | 'if_none' | 'if_some' | 'if_single' | 'if_multi'

macro-arg               ::= tdl-expression | expression-group

expression-group        ::= '(..' tdl-expression* ')'
```
