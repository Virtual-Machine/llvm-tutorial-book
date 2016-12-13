#Chapter 0 Introduction

In this tutorial we will work together to write a compiler for a simple toy programming language. Right up front we will make no claims of performance, safety, or functionality. The main objective will be to better understand how the LLVM api works when building a front-end and to better understand how compilers work in general. Maybe you just want to satisfy your curiousity or maybe you genuinely want to build the next great programming language of the future. In either case I hope this tutorial will be of great value to you.

We are going to write the compiler using Crystal. There are a few reasons for this decision. Primarily, I find Crystal to offer very clean syntax and by default comes with excellant bindings to LLVM. I want all functionality in our toy compiler to be explicit, easy to understand, debug, test, and monitor. With Crystal, I can easily ensure all the code is clear and concise and the bindings will stay out of our way. Secondarily, because Crystal is itself a LLVM front-end, there is a ton of information and examples directly in the Crystal source code. I highly recommend you spend some time reading the Crystal compiler source code before/during/after reading this tutorial.

The language will be imperative, statically typed, and compile to object code callable from C. It will discourage punction usage and strive to be explicit while terse. We will start by parsing everything at the top level, and gradually build in control flow and nested expressions expanding the initially sparse syntax.

We will call our toy language Emerald as a nod to both Crystal and Ruby. Further, the syntax will also be a major nod to both languages. Here is a snippet of our initial goal, showing some of the basic syntax elements.
```ruby
# I am a comment!
four = 2 + 2
puts four
puts 10 < 6
puts 11 != 10
```

While the above example may look simple, it is going to require us to cover some serious ground in our understanding of the LLVM api.  Already our simple syntax is going to require variables, a builtin puts command, and binary operators. We are going to have to be able to parse the structure of input files, understanding order of operations and expression context. But do not be discouraged. We are going to tackle this in easily digestable pieces. Once we have this much working, we will have a great base to begin extending our language with more powerful features.

Lookahead:

Information

[Chapter 1 - Compiler Basics](https://github.com/Virtual-Machine/llvm-tutorial-book/blob/master/chap-1-compiler-basics.md)  -- Incomplete

[Chapter 2 - LLVM Basics](https://github.com/Virtual-Machine/llvm-tutorial-book/blob/master/chap-2-llvm-basics.md)  -- Incomplete

Basic Architecture

[Chapter 3 - Lexer](https://github.com/Virtual-Machine/llvm-tutorial-book/blob/master/chap-3-lexer.md)  -- Incomplete

[Chapter 4 - Parser](https://github.com/Virtual-Machine/llvm-tutorial-book/blob/master/chap-4-parser.md)  -- Incomplete

[Chapter 5 - Code Generator](https://github.com/Virtual-Machine/llvm-tutorial-book/blob/master/chap-5-code-generator.md)  -- Incomplete

[Chapter 6 - Summary](https://github.com/Virtual-Machine/llvm-tutorial-book/blob/master/chap-6-summary.md)  -- Incomplete

Advanced Architecture

Chapter 7 - TBD




