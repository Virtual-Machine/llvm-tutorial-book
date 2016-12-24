#Chapter 6 Summary

If you made it this far then you can give yourself a big pat on the back. You made it! You have made a fully functioning toy compiler. You have seen the entire process from beginning to end.

While the toy compiler we made has all the same pieces as more mature compilers, it still needs some more work if we want this thing to be production ready. In fact, this is not meant to discourage you but currently this toy example is not very practical at all. But that is ok. We have a great skeleton in place and we can very easily add new tokens, node types, and code generation functionality to expand the power of our toy language.

With the basics now in place, you could try getting loops, if/else branches, or even class based functionality working. With the techniques seen in the tutorial you should be able to use simple C examples to aid you in this process. Once you see how Clang processes the tokens and AST you should feel confident enough to immitate the behaviour. Clang is LLVM's flagship implementation. If your approach mimics Clang's then you know you are on the right track to performant code.

But beyond the missing functionality there is still much more to know about the architecture. We did not even touch on optimizations, modules, scoping, etc... There is much you will want to play with if you want to get the full appreciation and understanding of the LLVM framework.