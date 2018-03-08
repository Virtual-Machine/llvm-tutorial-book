# Chapter 6 Summary

If you made it this far then you can give yourself a big pat on the back. You made it! You have made a fully functioning toy compiler. You have seen the entire process from beginning to end.

While the toy compiler we made has all the same pieces as more mature compilers, it still needs some more work if we want it to be production ready. In fact, this is not meant to discourage you but currently this toy example is not very practical at all. Nevertheless, we have a great skeleton in place and we can very easily add new tokens, node types, and code generation functionality to expand the power of our toy language.

With the basics now in place, you could try getting loops, if/else branches, or even class based functionality working. With the techniques seen in the tutorial you should be able to use simple C examples to aid you in this process. Once you see how Clang processes the tokens and AST you should feel confident enough to imitate the behaviour. Clang is LLVM's flagship implementation. If your approach mimics Clang's then you know you are on the right track to code that will perform well.

But beyond the missing functionality there is still much more to know about the architecture. We did not even touch on optimizations, modules, scoping, etc... There is much you will want to play with if you want to get the full appreciation and understanding of the LLVM framework.

Now that you have a basic grasp on compilers, one thing I can not recommend enough, is to study how other compilers implement their functionality. You will be surprised what you can learn by studying the compiler implementation of other languages. A great learning example is the Crystal compiler. The compiler is written in Crystal making it extremely simple to read through and it uses LLVM bindings itself which makes for a helpful study aid.

Along with Crystal, there are many languages written on top of the LLVM architecture, and each is an opportunity to absorb the real world knowledge and experience of a compiler implementation. While we focused on keeping our language simple, these languages will have a much deeper integration with LLVM's functionality. It can often be much more enlightening to see how a compiler implements something rather than trying to read manuals and header files in LLVM itself.

#### Next
[Chapter 7 - Implementing If/Else](https://github.com/Virtual-Machine/llvm-tutorial-book/blob/master/chap-7-if-else.md)