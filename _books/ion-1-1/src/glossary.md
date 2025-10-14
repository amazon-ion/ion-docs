# Glossary

**active encoding module**<br/>
An _encoding module_ whose symbol table and macro table are available in the current _segment_ of an Ion _document_.
The sequence of active encoding modules is set by an _encoding directive_.

**argument**<br/>
The sub-expression(s) within a macro invocation, corresponding to exactly one of the macro's parameters.

**declaration**<br/>
The association of a name with an entity (for example, a module or macro). See also _definition_. 
Not all declarations are definitions: some introduce new names for existing entities.

**definition**<br/>
The specification of a new entity.

**directive**<br/>
A keyword or unit of data in an Ion document that affects the encoding environment, and thus the way the document's data is encoded and decoded.
In Ion 1.0 there are two directives: _Ion version markers_, and the _symbol table directives_.
Ion 1.1 adds _encoding directives_.

**document**<br/>
A stream of octets conforming to either the Ion text or binary specification.
Can consist of multiple _segments_, perhaps using varying versions of the Ion specification.
A document does not necessarily exist as a file, and is not necessarily finite.

**E-expression**<br/>
See _encoding expression_.

**encoding directive**<br/>
In an Ion 1.1 segment, a top-level E-expression that invokes the implicit `$ion` macro.
Defines a new _encoding module sequence_ for the segment immediately following it.
The _symbol table directive_ is effectively a less capable alternative syntax.

**encoding environment**<br/>
The context-specific data maintained by an Ion implementation while encoding or decoding data. In
Ion 1.0 this consists of the current symbol table; in Ion 1.1 this is expanded to also include the Ion
spec version, the current macro table, and a collection of available modules.

**encoding expression**<br/>
The invocation of a macro in encoded data, aka e-expression.
Starts with a macro reference denoting the function to invoke.
The Ion text format uses "smile syntax" `(:macro ...)` to denote e-expressions. 
Ion binary devotes a large number of opcodes to e-expressions, so they can be compact.

**encoding module**<br/>
A _module_ whose symbol table and macro table can be used directly in the user data stream.

**encoding tag**<br/>
A way of conveying the encoding of a value (i.e. its _opcode_), separated from the value itself.

**expression**<br/>
A serialized syntax element that may produce values.
_Encoding expressions_ and values are both considered expressions, whereas NOP, comments, and IVMs, for example, are not. 

**inner module**<br/>
A _module_ that is defined inside another module and only visible inside the definition of that module.

**Ion version marker**<br/>
A keyword directive that denotes the start of a new segment encoded with a specific Ion version.
Also known as "IVM".

**macro**<br/>
A transformation function that accepts some number of streams of values, and produces a stream of values.

**macro definition**<br/>
Specifies a macro in terms of a _template_.

**module**<br/>
The data entity that defines and exports both symbols and macros.

**opcode**<br/>
A 1-byte, unsigned integer that tells the reader what the next expression represents
and how the bytes that follow should be interpreted.

**placeholder**<br/>
A special-purpose _encoding expression_ that is replaced by a macro _argument_ when evaluating the expansion of a _template_.

**qualified macro reference**<br/>
A macro reference that consists of a module name and either a macro name exported by that module,
or a numeric address within the range of the module's exported macro table. In text, these look
like :_module-name_::_name-or-address_.

**segment**<br/>
A contiguous partition of a _document_ that uses the same _encoding module sequence_.
Segment boundaries are caused by directives: an IVM, `set_symbols`, `add_symbols`, `set_macros`, `add_macros`, `use`, and `encoding` directives end segments (with a new one starting immediately afterward).
The `import` and `module` directives can also end a segment if they are redefining a module binding that was in the encoding module sequence.

**shared module**<br/>
A module that exists independent of the data stream of an Ion document. It is identified by a
name and version so that it can be imported by other modules.

**signature**<br/>
The part of a macro definition that specifies its "calling convention", in terms of the shape and type of arguments it accepts.
The signature is implicit in a macro definition; it is derived from the _placeholders_ that are in the _template_. 

**symbol table directive**<br/>
A top-level struct annotated with `$ion_symbol_table`.  Defines a new encoding environment
without any macros. Valid in Ion 1.0. In Ion 1.1, this is effectively a no-op because it has been replaced by the `add_symbols`, `set_symbols`, and `use` directives.

**system module**<br/>
A standard module named `$ion` that is provided by the Ion implementation, implicitly installed so
that the system symbols are available at all points within a document.
Subsumes the functionality of the Ion 1.0 system symbol table.

**system symbol**<br/>
A symbol provided by the Ion implementation via the system module `$ion`.
System symbols are available at all points within an Ion document, though the selection of symbols
varies by segment according to its Ion version.

**tagless-element sequence**<br/>
A list or s-expression that has homogeneous elements, allowing the type descriptor of the elements to be lifted into the 
container's definition for more compact representation of the child values.

**template**<br/>
The part of a macro definition that expresses its transformation of inputs to results.

**unqualified macro reference**<br/>
A macro reference that consists of either a macro name or numeric address, without a qualifying module name. 
These are resolved using lexical scope and must always be unambiguous.
