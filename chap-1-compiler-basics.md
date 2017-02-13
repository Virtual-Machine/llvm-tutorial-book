#Chapter 1 Compiler Basics

This chapter serves as a very basic crash course in compilers. This is going to be very explicit and to the point. Please feel free to fill this information in with lots of other sources when you get the chance!

Here are the basics of what you need to know.

###Steps of Standard Compiler Usage

1. User has a file with some source code the compiler understands. 
2. User runs the compiler executable on the source code file.
3. The compiler "lexes" file into a token array
4. The compiler "parses" the token array into an AST.
5. The compiler "code generates" the AST into machine code or intermediate language.
6. The intermediate language is converted to machine code if necessary and the user can then run the native machine code.

This is a gross simplification however it may introduce new concepts that are foreign. We will cover the terminology and details here.

**Lexing/Lexer**: A lexer is code designed to perform lexing. Lexing is the process of reading source code as an array of characters, and producing an array of tokens. The lexer decides where one keyword, identifier, variable, or other syntax component ends and the next one starts. Every language has the ability to decide exactly how characters are grouped and delineated to form tokens. Some languages use symbols like ';' to delineate the end of lines, while some languages use the newline escape sequence, "\n". Most languages use spaces to delineate tokens but the lexer can be programmed to recognize any grouping and order of characters to generate the final array of tokens.

**Tokens**: A token is simply a symbolic representation of exactly one keyword, identifier, variable, literal, or other component in the language. The token in its most basic form will hold the value of the given token as well as its semantic function in the language. It is useful for tokens to also carry their positional location in the file for later reference by the compiler. Tokens are the output of the lexer and input of the parser.

**Parsing/Parser**: The parser is responsible for taking the array of tokens produced by the lexer and generating what is known as an AST (Abstract Syntax Tree). The parser's job is actually twofold. First, the parser's job is to make sense of the sequence of tokens it receives to produce valid expressions in the form of AST nodes. Because of this functionality, the parser is going to find mistakes if they exist in the source file. Therefore the secondary function of the parser is to identify and notify the user of syntax errors in the source code of the input file.

**AST (Abstract Syntax Tree)**: The AST is a tree-like representation of the program code structured in such a way that the code generator can walk through the nodes to eventually produce machine code that is directly executable. Walking an AST is simply the process of moving along the nodes of the tree from top to bottom, parent nodes to child nodes and back. The AST nodes hold references to other nodes, making it possible to 'walk' the syntax of the language. These nodes typically also carry the location information to make error messages useful to developers in the event of syntax errors.

**Code Generator**: The code generator takes the AST as input and produces intermediate or machine code. The code generator "walks" the nodes of the AST, using the references it has to other nodes to generate the necessary instructions in the output code. Depending on the compiler architecture you may need to assemble your output intermediate representation to machine code prior to the final execution.

### Advanced Compiler Stages

If we want to get more advanced we can add two more stages to this process. The first advanced stage would be an AST simplifying step. This would occur between parsing and the code-generation. The job of the AST simplification stage is to walk the nodes of the AST and look for expressions that can be evaluated at compile time to single nodes. The more nodes that can be collapsed during this stage, the less work required for the code-generation to perform and the fewer calculations required at run-time. This can definitely be viewed as a code optimization.

The second advanced stage is an actual optimization step. Principally, these optimizations are run during or after code-generation and are also sometimes performed at link-time. The goal of this step is to look for patterns in the generated machine or assembly code that will allow simplifications to the code without affecting the final result. Depending on your needs, this step can be tuned between compile-time or run-time speed and between performance and safety.

In our toy example we will be using some AST simplification techniques as required to make use of the builder API, but we will not be spending any time with explicit optimizations. Feel free to use the toy example as a means to experiment with LLVM's optimizations and better understand how they manipulate the code to improve performance. If you compare source code to generated LLVM ir with optimizations, you will notice that the optimizations can be quite effective at turning function bodies into inline values and removing unnecessary calculations from statements.


