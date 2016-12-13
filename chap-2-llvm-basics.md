#Chapter 2 LLVM Basics

This chapter is a crash course in LLVM's most basic concepts and terminologies. This is by no means complete, but it will be enough to give you a decent idea of how LLVM works and how you will be using its api.

First and foremost, we will be putting some blinders on and using LLVM in a very simplistic way. Despite the fact that LLVM exposes a very detailed modular api with lots of control at all stages of code compilation, we are going to take a very lazy, and in some cases perhaps even naive approach, to working with it. That is ok for now because A) its more rewarding to get to a working stage quickly, and B) LLVM has lots of tooling that will make our naive code run plenty efficiently for the time being. Once we understand the basics, then we can begin to add more advanced techniques to our approach.

So what do I mean by us taking a lazy approach? What I mean is we are going to let the LLVM ir builder api do the heavy lifting for us and we are not going to spend much, if any, time tinkering with the generated ir other than applying the standard optimizations LLVM offers. This means if our lexer and parser can generate an AST of nodes that the LLVM ir builder api understands, we are essentially done. The only remaining work will be to call the builder api wth the correct references to each of our nodes.

So what do I mean by us taking a naive approach? Full disclaimer, I am very much still a student of compilers and LLVM, I am probably doing many things that a compiler/LLVM expert would consider naive or ignorant. Also in the interest of enlightening people without adding unnecessary confusion I will be trying to keep things extremely simplistic. This means I will try to avoid using lots of indirection, complex abstractions, inheritance, and implicit behaviour in the compiler even if the end result is more verbose code. The code may not follow all the best practices but it will be easy to read and understand.

Here are some gross simplications that should help you get started with LLVM. Fill your knowledge in with more details as it becomes necessary.

1. The main unit of grouping in LLVM is the module. You can have several modules in a program, and each module will contain functions, global variables and externalized interface. In our simplistic, naive approach we will never use more than one module but know that it is possible.
2. Everything inside a module is a llvm Value descendent. These include but are not limited to functions, blocks, expressions, instructions, etc... A nice way to visually think of this is: Module -> Function -> BasicBlock -> Instructions.
3. BasicBlocks are an important concept. BasicBlocks are the cornerstone of the ir builder API and for good reason. A BasicBlock is simply a list of instructions in which the only way they can be executed is from first to last in order with no control flow. Think of a function body with no logic statements or gotos and you are likely looking at a BasicBlock.


Further Reading and References:
1. [LLVM for Grad Students by Adrian Sampson](https://www.cs.cornell.edu/~asampson/blog/llvm.html)
2. [How to get started with the LLVM C API by Paul Smith](https://pauladamsmith.com/blog/2015/01/how-to-get-started-with-llvm-c-api.html)
3. [Create a working compiler with the LLVM framework, Part 1 by Arpen Sen](https://www.ibm.com/developerworks/library/os-createcompilerllvm1/)
4. [My First LLVM Compiler by Wilfred Hughes](http://www.wilfred.me.uk/blog/2015/02/21/my-first-llvm-compiler/)
