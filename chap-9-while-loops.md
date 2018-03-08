# Chapter 9 While Loops

In chapter 7 we implemented if/else statements. The good news is that implementing while loops are fairly similar. Much like if/else statements, while loops can be implemented in LLVM IR using several blocks to control the flow of execution.

Here is a diagram that can be helpful to see how this effectively translates in a real world example:
![While to IR](https://raw.githubusercontent.com/Virtual-Machine/llvm-tutorial-book/master/diagrams/img/while_to_ir.png)