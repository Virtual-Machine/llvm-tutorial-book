# LLVM Frontend Tutorial

This is the main repository for my LLVM tutorial.

*WARNING* This project is in progress. The lexer and parser are functional, though subject to refactoring and possible bugs. The code generator is not yet complete. Until this warning is removed, source code is subject to change and/or be incomplete.

The project intention is to create a user friendly introduction to llvm, compilers, and programming language creation in general.

Through the chapters of this tutorial we will create a working compiler for a toy language. Initially we will keep the syntax very simple to get to a working product quickly and then iteratively build on new functionality and syntax to gradually make the toy language more expressive and powerful.

If anyone notices anything out of date or that is not factually correct, I welcome the knowledge. I am hoping to learn a lot from writing this.

###Todo

☐ Write node walking algorithm

☐ Write code generation for node types

☐ Clean and refactor code

☐ Integrate code into chapter texts

☐ Add diagrams for program behaviour

☐ Add more specs

###Working

Lexer is able to lex primary example, producing expected token array

Parser is able parse primary example, producing expected AST

Furthermore Parser is able to parse numeric expressions containing parenthesis, and obeys order of BDMAS (no exponents yet).

There are useful examples in /example_ir to see working LLVM IR and Crystal Builder API usage.

###Partial

Chapters 0-6 contains partial and somewhat scattered information. Despite this early rough stage, it is likely still very useful.
