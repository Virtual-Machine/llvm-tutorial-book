# LLVM Frontend Tutorial

![Travis Badge](https://travis-ci.org/Virtual-Machine/llvm-tutorial-book.svg?branch=master)

This is the main repository for my LLVM tutorial.

**WARNING** This project is still in the early phase. The lexer, parser and code generator are functional, though subject to refactoring and possible bugs. Until this warning is removed, source code is subject to change. Chapter texts remain incomplete, yet useful at the moment. Compiler meets basic example requirements and beyond, but there are more additions planned.

The project intention is to create a user friendly introduction to llvm, compilers, and programming language creation in general.

Through the chapters of this tutorial we will create a working compiler for a toy language. Initially we will keep the syntax very simple to get to a working product quickly and then iteratively build on new functionality and syntax to gradually make the toy language more expressive and powerful.

If anyone notices anything out of date or that is not factually correct, I welcome the knowledge. I am hoping to learn a lot from writing this.

I am also concurrently maintaining a repository of example ir demos that is useful for exploring how llvm ir works to corresponding code samples. 
[Example LLVM IR](https://github.com/Virtual-Machine/ir-examples)

```bash
#quick start
crystal build emeraldc.cr #generates emerald compiler emeraldc
llc std-lib.ll            #generates std-lib.s ready for linking with output.s
# By default emeraldc targets test_file.cr
./emeraldc -h #show emeraldc help
./emeraldc -l -a -r -i -v #compile test_file.cr with all debug info
./emeraldc -d #same as -l -a -r -i -v
./emeraldc file_of_your_choice.cr #choose file to compile
./emeraldc -q #no generated output.ll
./emeraldc -f #full compilation to output binary
./emeraldc -c #clean all output files
./emeraldc -n #no color output
./emeraldc -e #execute full compilation binary
./emeraldc -t #execute tests in spec/
./emeraldc -o #optimize llvm ir
```

###Todo

☐ Refactor code

☐ Write text for chapters
 - Chapter 9

☐ Integrate code into chapter texts
 - Chapter 3
 - Chapter 4
 - Chapter 5
 - Chapter 7
 - Chapter 8
 - Chapter 9

☐ Use refactored code to produce compiler versions corresponding to chapter texts
  - Chapter 3
  - Chapter 4
  - Chapter 5
  - Chapter 7
  - Chapter 8
  - Chapter 9

☐ Add diagrams for program behaviour
 - walk detail
 - resolve_value detail
 - ir generation detail


###Demo With Debug Output

demo_file.cr
```crystal
four = 2 + 2
puts four + 1
puts 10 < 6 + 1 * 2
```

```bash
./emeraldc demo_file.cr -d
```

output:

![Output](https://raw.githubusercontent.com/Virtual-Machine/llvm-tutorial-book/master/diagrams/img/demo_output.png)

