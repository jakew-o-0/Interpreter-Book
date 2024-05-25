### 1.1 Lexical analysis
two transformations will take place:
- source code -> tokens -> AST
As In, source code gets fed to a lexer that will create tokens that will be used to create an Abstract syntax tree.

Tokens are generated through a lexer/tokenizer/scanner, through lexical analysis of the source code. Done by breaking the source code down to specific language features, often done through using white space as a delimiter. Though, white space may be a token in some implementations where it is a part of the syntax *(python)*
- "let x = 5+5;" may end up looking like "[LET, IDENTIFIER(X), EQUAL_SIGN, INTEGER(5), PLUS_SIGN, INTEGER(5)]" 

- Tokens may contain useful metadata such as file name, line and column
- When defining types, such as integers, conversions may be done in later parts of the interpreter - the parsing or evaluation stage.

### 1.2 Defining Our Tokens
##### non-specific tokens
For aspects of syntax that cannot be concretely defined, such as int literals or variable names, they should just be defined as what they are. For example an int literal should be defined as being an int with a reference to what the literal is, and a variable name should be defined as an identifier with a reference to what the "variable" name actually is.

##### specific tokens
For deterministic syntax, they should be unique tokens to fully express each keyword within the syntax. For example a "let" keyword should have a unique token as to avoid confusion with an identifier or string literal. This will apply to other syntactical rules as in special characters such as *; or () or {}*

### 1.3 The Lexer
- should take in the source code
	- for large amounts of code with multiple files it may be best to buffer the source code to reduce memory consumtion.
- has a function call that returns the next token
- no need to buffer tokens. instead repeatedly call the nextToken fuction until 'EOF' is returned.