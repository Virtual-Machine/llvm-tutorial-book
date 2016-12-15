#Chapter 4 Parser

This step is going to be the most complicated, but if you can get through and understand this, then the rest is going to be a piece of cake. We currently are able to use our Lexer to get an array of Tokens. We now wish to parse the tokens into an AST (Abstract Syntax Tree). It gets this name due to the tree like structure it produces when fully parsed. Every literal, expression, block, return, if, while, def, etc... is going to have its own node. Each of these nodes will reference other nodes to indicate how they are related to one another. 

For instance, the binary operation 2 + 2 could be looked at as a binary expression node, with an operator node represented by the plus symbol, and a left hand side and right hand side expressions that are each in this case simply a number literal of 2. In this example the binary operator expression node would be considered the root, while the remaining nodes are its children. This tree like structure is very important as it makes our code-generation stage much more simple. In order to translate the AST into LLVM IR we simply will walk the AST, inspecting nodes as we go, and calling the LLVM IR Builder api with references to the respective child nodes.

```
BinaryExpressionNode -> 2 + 2
    Operator         -> +
    LHS              -> 2
    RHS              -> 2
```

In order to create our AST we are going to need a class for each node type so as to allow each node to have instance variables that reflect the required child nodes for each node type that LLVM understands and that we wish to port into our language. Currently our language is still pretty simple, so we will only require a few node types to get a functional AST. As we require more functionality in our language, we will simply just have to add new node types with instance variables reflecting the call signature of the related IR builder calls.

Our simple language currently only requires expression nodes, binary operator nodes, function calls, variable declarations and literals for our primitive types. We will implement the puts command as a language built-in and all our code will be treated as though its being called from the main function and therefore appended to the end of the main function's BasicBlock as we go.

Our parser will work by inspecting the current token in the array. The parser will be aware of each node type and how it relates to other node types in sequence. Each line will be treated as an expression, of which itself may consist of multiple other expressions. The parser will determine which tokens should be expected following a given token, if those tokens are not found, an error will be generated to help the user determine where a syntax error is occuring. Otherwise the parser will continue to take the tokens and generate the required node structure to form the final AST. We should be able to easily inspect our AST at the end of this stage to visually debug and ensure our code-generation calls are getting the correct information.
