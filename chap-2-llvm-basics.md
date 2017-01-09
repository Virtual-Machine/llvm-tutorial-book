#Chapter 2 LLVM Basics

This chapter is a crash course in LLVM's most basic concepts and terminologies. This is by no means complete, but it will be enough to give you a decent idea of how LLVM works and how you will be using its api.

First and foremost, we will be putting some blinders on and using LLVM in a very simplistic way. Despite the fact that LLVM exposes a very detailed modular api with lots of control at all stages of code compilation, we are going to take a very lazy, and in some cases perhaps even naive approach, to working with it. That is ok for now because A) its more rewarding to get to a working stage quickly, and B) LLVM has lots of tooling that will make our naive code run plenty efficiently for the time being. Once we understand the basics, then we can begin to add more advanced techniques to our approach.

So what do I mean by us taking a lazy approach? What I mean is we are going to let the LLVM ir builder api do the heavy lifting for us and we are not going to spend much, if any, time tinkering with the generated ir other than applying the standard optimizations LLVM offers. This means if our lexer and parser can generate an AST of nodes that the LLVM ir builder api understands, we are essentially done. The only remaining work will be to call the builder api wth the correct references to each of our nodes.

So what do I mean by us taking a naive approach? Full disclaimer, I am very much still a student of compilers and LLVM, I am probably doing many things that a compiler/LLVM expert would consider naive or ignorant. Also in the interest of enlightening people without adding unnecessary confusion I will be trying to keep things extremely simplistic. This means I will try to avoid using lots of indirection, complex abstractions, inheritance, and implicit behaviour in the compiler even if the end result is more verbose code. The code may not follow all the best practices but it will be easy to read and understand.

Here are some gross simplications that should help you get started with LLVM. Fill your knowledge in with more details as it becomes necessary.

1. The main unit of grouping in LLVM is the module. You can have several modules in a program, and each module will contain functions, global variables and an externalized interface. In our simplistic, naive approach we will never use more than one module but know that it is possible.
2. Everything inside a module is a llvm Value descendent. These include but are not limited to functions, blocks, expressions, instructions, etc... A nice way to visually think of this is: **Module** can have **Functions** which have a **BasicBlock** which is made up of **Instructions**. Values are a way for each component to reference each other and is the basis for compile time mathematic calculations.
3. BasicBlocks are an important concept. BasicBlocks are the cornerstone of the ir builder API and for good reason. A BasicBlock is simply a list of instructions in which the only way they can be executed is from first to last in order with no control flow. Think of a function body with no logic statements or gotos and you are likely looking at a BasicBlock.
4. A function is basically a block of code that accepts a given list of typed parameters and returns a typed value. LLVM views it the same way. We will be initially running all our code inside a main function that we will initialize by giving it a C main interface. A simplified C main function takes no parameters and returns an integer. Therefore in LLVM we say that it will take an empty array of LLVM type values, and return a LLVM 32 bit integer.
5. LLVM type values are exactly what they sound like, it is LLVMs internal representation of type as related to an LLVM Value object. This is the system where by your code can be statically typed and compiled to object code callable from C. By giving our main function a C interface using LLVM types, and by flagging our main function as a LLVM::Linkage::External we have allowed linkers to identify our object code's main function as if it were compiled from C.
6. The LLVM builder api has the notion of position. A given builder has to be directed where it will be appending new instructions. In the case of our initial simplified approach we will be appending all our instructions to the BasicBlock of the main function. As you can imagine this sets up the primary means of constructing function bodies across multiple functions in a module.
7. Finally once you are finished compiling the instructions into your module, you will want to dump the output to LLVM IR ll files. The resultant [name_of_file].ll can now be treated like any LLVM IR as if it were just compiled straight from C. This includes all the optimizations and plugins available in the LLVM architecture. It is also ready to be compiled to object code and linked with any other object code compiled from other sources. The file.ll theoretically can be compiled to any target architecture so long as the LLVM IR is not doing anything machine specific.
8. Because our example is compiling instructions into a main function, if we execute the compiled and linked version of our output, it should immediately invoke the main function and we should see the results of our instructions.

To get you started quickly here is a quick glossary of some LLVM ir instructions and what they do:

```llvm
;alloca - reserve space in memory for typed variable

    %fourp = alloca i32

;store - put value into allocated memory

    store i32 4, i32* %fourp

;load - get value stored in allocated memory

    %value = load i32, i32* %fourp

;getelementptr - get a pointer to a subelement, 
;- useful for converting a char buffer into a const char*

    %buffer = alloca [79 x i8]
    %bpointer = getelementptr [79 x i8], [79 x i8]* %buffer, i32 0, i32 0

;call - call a named function with return type and params

    call i32 @puts( i8* %bufferp )

;br - jumps to a code block based on the provided value or unconditionally jumps

    br i1 false, label %if_block, label %else_block ;conditional jump
    br label %code_block ;unconditional jump

;icmp - compare two values with a given operator
;- eq, ne, ult, ugt, uge, ule, slt, sgt, sge, sle
;- equals, not equal, signed and unsigned less than, greater than, less than or equal, greater than or equal
;- returns i1

    %comparison = icmp eq i32 2, 0

;ret - return a value from the active function

    ret i32 0

;sext & zext - extend an integer to a larger bit size
;- sext is sign extended, zext is zero extended
    
    %result = zext i1 %value to i32
    %result = sext i1 %value to i32

;trunc - reduce an integer size to a smaller bit size

    %result = trunc i32 %value to i1
```


Further Reading and References:

1. [LLVM for Grad Students by Adrian Sampson](https://www.cs.cornell.edu/~asampson/blog/llvm.html)

2. [How to get started with the LLVM C API by Paul Smith](https://pauladamsmith.com/blog/2015/01/how-to-get-started-with-llvm-c-api.html)

3. [Create a working compiler with the LLVM framework, Part 1 by Arpen Sen](https://www.ibm.com/developerworks/library/os-createcompilerllvm1/)

4. [My First LLVM Compiler by Wilfred Hughes](http://www.wilfred.me.uk/blog/2015/02/21/my-first-llvm-compiler/)
