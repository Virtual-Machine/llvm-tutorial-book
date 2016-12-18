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

If we use our initial example code from chapter 0.

```ruby
# I am a comment!
four = 2 + 2
puts four
puts 10 < 6
puts 11 != 10
```

We will be parsing this into an AST that will look something like this.
```
Expressions Node : [four = 2 + 2, puts four, puts 10 < 6, puts 11 != 10]
[0]
|-> Variable Declaration Node : four = 2 + 2
|---> Binary Expression Node : 2 + 2
|-----> Number Literal : 2
|-----> Number Literal : 2
[1]
|-> Call Expression Node : puts four
|---> Variable Lookup Expression : four
[2]
|-> Call Expression Node : puts 10 < 6
|---> Binary Expression Node : 10 < 6
|-----> Number Literal : 10
|-----> Number Literal : 6
[3]
|-> Call Expression Node : puts 11 != 10
|---> Binary Expression Node : 11 != 10
|-----> Number Literal : 11
|-----> Number Literal : 10
```

Something that may be of use to you for experimental purposes is to see Clang's AST representation for simple C code. This is useful as LLVM uses Clang's AST in its own codegen methods and should be informative to browse. Below is a simple C code example.

```c
int addFour(int x) {
    return x + 4;
}


int main(){
    int four = addFour(0);
}

```

```bash
clang -cc1 -ast-dump name_of_file.c
```

If we scrape out some of the extraneous information we can see Clang's AST for this code:
```
|-FunctionDecl 0x7f9247882400 <main.c:1:1, line:3:1> line:1:5 used addFour 'int (int)'
| |-ParmVarDecl 0x7f92478316d8 <col:13, col:17> col:17 used x 'int'
| `-CompoundStmt 0x7f9247882590 <col:20, line:3:1>
|   `-ReturnStmt 0x7f9247882578 <line:2:2, col:13>
|     `-BinaryOperator 0x7f9247882550 <col:9, col:13> 'int' '+'
|       |-ImplicitCastExpr 0x7f9247882538 <col:9> 'int' <LValueToRValue>
|       | `-DeclRefExpr 0x7f92478824f0 <col:9> 'int' lvalue ParmVar 0x7f92478316d8 'x' 'int'
|       `-IntegerLiteral 0x7f9247882518 <col:13> 'int' 4
`-FunctionDecl 0x7f92478825f8 <line:6:1, line:8:1> line:6:5 main 'int ()'
  `-CompoundStmt 0x7f92478827e8 <col:11, line:8:1>
    `-DeclStmt 0x7f92478827d0 <line:7:2, col:23>
      `-VarDecl 0x7f92478826b0 <col:2, col:22> col:6 four 'int' cinit
        `-CallExpr 0x7f92478827a0 <col:13, col:22> 'int'
          |-ImplicitCastExpr 0x7f9247882788 <col:13> 'int (*)(int)' <FunctionToPointerDecay>
          | `-DeclRefExpr 0x7f9247882710 <col:13> 'int (int)' Function 0x7f9247882400 'addFour' 'int (int)'
          `-IntegerLiteral 0x7f9247882738 <col:21> 'int' 0

```

