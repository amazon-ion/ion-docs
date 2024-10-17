# Module grammar

```bnf
encoding-directive ::= '$ion_encoding::(' module-body ')'

shared-module      ::= '$ion_shared_module::' ion-version-marker '::(' catalog-key module-body ')'

ion-version-marker ::= '$ion_1_0' | '$ion_1_1'

module-body        ::= import* inner-module* symbol-table? macro-table?

import             ::= '(import ' module-name catalog-key ')'

catalog-key        ::= catalog-name catalog-version?

catalog-name       ::= string

catalog-version    ::= int // positive, unannotated

inner-module       ::= '(module' module-name import* symbol-table? macro-table? ')'

module-name        ::= unannotated-identifier-symbol



// Symbol Tables

symbol-table       ::= '(symbol_table' symbol-table-entry* ')'

symbol-table-entry ::= module-name | symbol-list

symbol-list        ::= '[' ( symbol-text ',' )* ']'

symbol-text        ::= symbol | string


// Macro Tables

macro-table             ::= '(macro_table' macro-table-entry* ')'

macro-table-entry       ::= macro-definition
                          | macro-export
                          | module-name
                     
macro-definition        ::= '(macro' macro-name-declaration signature tdl-expression ')'

macro-export            ::= '(export' qualified-macro-ref macro-name-declaration? ')'

macro-name-declaration  ::= macro-name | 'null'

qualified-macro-ref     ::= module-name '::' macro-ref

macro-ref               ::= macro-name | macro-addr

qualified-macro-name    ::= module-name '::' macro-name

macro-name              ::= unannotated-identifier-symbol

macro-addr              ::= unannotated-uint 

signature               ::= '(' macro-parameter* ')'

macro-parameter         ::= parameter-encoding? parameter-name parameter-cardinality?

parameter-encoding      ::= (primitive-encoding-type | macro-name | qualified-macro-name)'::'

primitive-encoding-type ::= 'uint8' | 'uint16' | 'uint32' | 'uint64'
                          |  'int8' |  'int16' |  'int32' |  'int64'
                          | 'float16' | 'float32' | 'float64'
                          | 'flex_int' | 'flex_uint' | 'flex_sym' | 'flex_string'

parameter-name          ::= unannotated-identifier-symbol

parameter-cardinality   ::= '!' | '*' | '?' | '+'
```
