# LLVM Frontend Tutorial

This is the main repository for my LLVM tutorial.

*WARNING* This project is in progress. The lexer, parser and code generator are functional, though subject to refactoring and possible bugs. Until this warning is removed, source code is subject to change and/or be incomplete.

The project intention is to create a user friendly introduction to llvm, compilers, and programming language creation in general.

Through the chapters of this tutorial we will create a working compiler for a toy language. Initially we will keep the syntax very simple to get to a working product quickly and then iteratively build on new functionality and syntax to gradually make the toy language more expressive and powerful.

If anyone notices anything out of date or that is not factually correct, I welcome the knowledge. I am hoping to learn a lot from writing this.

```bash
#quick start
crystal build emeraldc.cr #generates emerald compiler emeraldc
# By default emeraldc targets test_file.cr
./emeraldc -h #show emeraldc help
./emeraldc -t -a -r -i -v #compile test_file.cr with all debug info
./emeraldc file_of_your_choice.cr #choose file to compile
./emeraldc -q #no generated output.ll
./emeraldc -f #full compilation to output binary
./emeraldc -c #clean all output files
./emeraldc -n #no color output
./emeraldc -e #execute full compilation binary
```

###Todo

☐ Write code generation for more node types

☐ Clean and refactor code

☐ Integrate code into chapter texts
 - Chapter 3
 - Chapter 4
 - Chapter 5

☐ Add diagrams for program behaviour
 - lexer detail
 - parser detail
 - walk detail
 - resolve_value detail
 - ir generation detail

☐ Add more specs
 - test bad syntax is caught with helpful error messages

###Working

Lexer is able to lex primary example, producing expected token array

Parser is able parse primary example, producing expected AST

Furthermore Parser is able to parse numeric expressions containing parenthesis, and obeys order of BDMAS (no exponents yet).

There are useful examples in /example_ir to see working LLVM IR and Crystal Builder API usage.

Generator is able to walk nodes, declaring and referencing variables, resolving values and outputting a valid LLVM IR module complete with puts capability.

###Partial

Chapters 0-6 contains partial and somewhat scattered information. Despite this early rough stage, it is likely still very useful.
