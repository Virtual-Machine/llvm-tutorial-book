#Chapter 7 If / Else

Through the first section of the book, we concerned ourselves with only the basics of a toy compiler. At the end of chapter 5 our compiler is able to work with basic expressions in a procedural, line by line fashion. However if we want to add some sections of code that only execute when given conditions are true we need to introduce if else statements.

If else statements are actually pretty easy to implement based on the working parts we already have. We do however need to start learning about basic blocks in a little bit more depth and begin to understand how basic blocks can be combined with conditional checks to create conditional logic in our code.

To keep things really simple, we will not yet introduce an elsif keyword and will only allow for if and else statements. With this setup we can make some generalizations about how our compiler will handle conditional checks. Our previous experience with LLVM showed us that we could create simple working code by injecting instructions into a basic block. Now that we are going to be implementing if else expressions we will need more than one basic block.

The easiest way to think about an if expression in LLVM is that you will need atleast 3 basic blocks (4 if it contains an else block) to achieve this behaviour. If we analyze a crystal if / else, we can see how the instructions relate to the different basic blocks.

```crystal
# If / Else
if 2 < 3
    puts "true"
else
    puts "false"
end
```

Any code preceding the if statement along with the conditional if check will go into the first block. That block will then jump to either the if block or the else block based on the result of the conditional check. Finally both the if block and else block will jump to an exit block which will contain any instructions following the end keyword.

```crystal
if 2 < 3
    puts "true"
end
```

In this case any code preceding the if statement along with the conditional if check will go into the first block. If the conditional evaluates true then it will jump to the if block, otherwise it will jump to the exit block. The if block also unconditionally jumps to the exit block.

Therefore to implement if else blocks we need functionality to allow us to add basic blocks into our main function, keeping track of what basic block is active, change the active block as we walk through our nodes, and append instructions onto the active block. All of this functionality will be implemented into our State class. When we are walking our AST, the state module will concern itself with this information, appending blocks as needed, and appending instructions to the correct block.

One final thing we need to implement is the ability to close our blocks correctly. Due to the order of nodes in our AST, we actually need to keep track of the closing statements of our blocks and only insert them once all other instructions have been inserted into the block. The easiest way to accomplish this is to save all these instructions into an array and inject them after all other instructions have been appended. There are only two types of closing statements, a conditional jump and unconditional jump which will allow our blocks to flow correctly into each other as required.

With all this implemented, our compiler should have no problem parsing nested if else statements, generating all the necessary blocks required, and inserting the instructions into the correct blocks. We still only have one function, but that function can now consist of many interrelated blocks that can flow to one another as required.
