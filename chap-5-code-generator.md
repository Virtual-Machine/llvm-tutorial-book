#Chapter 5 Code Generator

While the parser's job was to convert an array of tokens into a structured AST, the code generator's job is to make the transition from AST to either intermediate or binary code. Code generation is completed by walking along the nodes of the AST and making sense of the structure. This is a recursive process, as the code generator must walk to the terminal nodes before resolving an expression. The final result will be all the parsed expressions into the module which will then be dumped as LLVM IR.

It can be helpful to have an idea of what a given AST will translate into IR code, even if you do not plan to write that IR yourself. Merely the structure of that IR will be informative as how to walk the AST and generate the required builder calls via LLVM's IR Builder API. Just as in the last chapter, we can use clang to emit the AST and the LLVM IR for simple C examples to better understand how an AST translates to LLVM IR. Forgive this ugly C example, I am using variables to prevent Clang from outputting optimized LLVM IR that is non-informative. If you know how to output raw LLVM IR without collapsing number literals please let me know.

```c
// example_clang/main2.c

int main(){
    int number;
    int two = 2, three = 3, four = 4;
    if (two + three * four < three) {
        number = two;
    } else {
        number = 5;
    }
    return number;
}
```

```bash
clang -cc1 -ast-dump name_of_file.c
clang -cc1 -emit-llvm name_of_file.c
```

Simplified AST:
```
`-FunctionDecl 0x7fc33a831718 <main2.c:1:1, line:10:1> line:1:5 main 'int ()'
  `-CompoundStmt 0x7fc33a8829b8 <col:11, line:10:1>
    |-DeclStmt 0x7fc33a882470 <line:2:5, col:15>
    | `-VarDecl 0x7fc33a882410 <col:5, col:9> col:9 used number 'int'
    |-DeclStmt 0x7fc33a882658 <line:3:5, col:37>
    | |-VarDecl 0x7fc33a882498 <col:5, col:15> col:9 used two 'int' cinit
    | | `-IntegerLiteral 0x7fc33a8824f8 <col:15> 'int' 2
    | |-VarDecl 0x7fc33a882528 <col:5, col:26> col:18 used three 'int' cinit
    | | `-IntegerLiteral 0x7fc33a882588 <col:26> 'int' 3
    | `-VarDecl 0x7fc33a8825b8 <col:5, col:36> col:29 used four 'int' cinit
    |   `-IntegerLiteral 0x7fc33a882618 <col:36> 'int' 4
    |-IfStmt 0x7fc33a882928 <line:4:5, line:8:5>
    | |-<<<NULL>>>
    | |-<<<NULL>>>
    | |-BinaryOperator 0x7fc33a8827c0 <line:4:9, col:30> 'int' '<'
    | | |-BinaryOperator 0x7fc33a882758 <col:9, col:23> 'int' '+'
    | | | |-ImplicitCastExpr 0x7fc33a882740 <col:9> 'int' <LValueToRValue>
    | | | | `-DeclRefExpr 0x7fc33a882670 <col:9> 'int' lvalue Var 0x7fc33a882498 'two' 'int'
    | | | `-BinaryOperator 0x7fc33a882718 <col:15, col:23> 'int' '*'
    | | |   |-ImplicitCastExpr 0x7fc33a8826e8 <col:15> 'int' <LValueToRValue>
    | | |   | `-DeclRefExpr 0x7fc33a882698 <col:15> 'int' lvalue Var 0x7fc33a882528 'three' 'int'
    | | |   `-ImplicitCastExpr 0x7fc33a882700 <col:23> 'int' <LValueToRValue>
    | | |     `-DeclRefExpr 0x7fc33a8826c0 <col:23> 'int' lvalue Var 0x7fc33a8825b8 'four' 'int'
    | | `-ImplicitCastExpr 0x7fc33a8827a8 <col:30> 'int' <LValueToRValue>
    | |   `-DeclRefExpr 0x7fc33a882780 <col:30> 'int' lvalue Var 0x7fc33a882528 'three' 'int'
    | |-CompoundStmt 0x7fc33a882878 <col:37, line:6:5>
    | | `-BinaryOperator 0x7fc33a882850 <line:5:9, col:18> 'int' '='
    | |   |-DeclRefExpr 0x7fc33a8827e8 <col:9> 'int' lvalue Var 0x7fc33a882410 'number' 'int'
    | |   `-ImplicitCastExpr 0x7fc33a882838 <col:18> 'int' <LValueToRValue>
    | |     `-DeclRefExpr 0x7fc33a882810 <col:18> 'int' lvalue Var 0x7fc33a882498 'two' 'int'
    | `-CompoundStmt 0x7fc33a882908 <line:6:12, line:8:5>
    |   `-BinaryOperator 0x7fc33a8828e0 <line:7:9, col:18> 'int' '='
    |     |-DeclRefExpr 0x7fc33a882898 <col:9> 'int' lvalue Var 0x7fc33a882410 'number' 'int'
    |     `-IntegerLiteral 0x7fc33a8828c0 <col:18> 'int' 5
    `-ReturnStmt 0x7fc33a8829a0 <line:9:5, col:12>
      `-ImplicitCastExpr 0x7fc33a882988 <col:12> 'int' <LValueToRValue>
        `-DeclRefExpr 0x7fc33a882960 <col:12> 'int' lvalue Var 0x7fc33a882410 'number' 'int'

```

Simplified LLVM IR:
```
; Function Attrs: nounwind ssp uwtable
define i32 @main() #0 {
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  store i32 0, i32* %1, align 4
  store i32 2, i32* %3, align 4
  store i32 3, i32* %4, align 4
  store i32 4, i32* %5, align 4
  %6 = load i32, i32* %3, align 4
  %7 = load i32, i32* %4, align 4
  %8 = load i32, i32* %5, align 4
  %9 = mul nsw i32 %7, %8
  %10 = add nsw i32 %6, %9
  %11 = load i32, i32* %4, align 4
  %12 = icmp slt i32 %10, %11
  br i1 %12, label %13, label %15

; <label>:13:                                     ; preds = %0
  %14 = load i32, i32* %3, align 4
  store i32 %14, i32* %2, align 4
  br label %16

; <label>:15:                                     ; preds = %0
  store i32 5, i32* %2, align 4
  br label %16

; <label>:16:                                     ; preds = %15, %13
  %17 = load i32, i32* %2, align 4
  ret i32 %17
}
```

If we ignore all the variable allocations and loads, we can simply this IR further. Here is the core functionality of the above LLVM IR with comments:
```
%9 = mul nsw i32 %7, %8                 ; Multiply 3 by 4 = 12
%10 = add nsw i32 %6, %9                ; Add 2 to 12 = 14
%12 = icmp slt i32 %10, %11             ; If 14 < 3 == false
br i1 %12, label %13, label %15         ; If true goto label %13, else label %15

; <label>:13:                           ; If block
  %14 = load i32, i32* %3, align 4
  store i32 %14, i32* %2, align 4       ; Store 2 into variable %2
  br label %16

; <label>:15:                           ; Else block      
  store i32 5, i32* %2, align 4         ; Store 5 into variable %2
  br label %16

; <label>:16:                           ; Finally
    %17 = load i32, i32* %2, align 4    ; Get value in variable %2
    ret i32 %17                         ; Return value
}

```

Of particular interest is how it resolved the if condition in reverse order of the AST node walking. Although the multiplication node is the furthest node from the parent node in the expression, it is code generated first. It then follows this up the AST chain, by generating the binary addition, then the binary comparison, and then the jump to the if and else blocks. It parsed these operations into its AST considering order of operations. This forced the multiplication into a further node than the addition and comparison operations to ensure it was code generated first in the AST walking process.

One thing you may be aware of if you tried my example without the use of variables is that Clang simplifies number literal expressions prior to walking the final AST and performing code generation. This is not only a valid approach to making the code generation process more simple, but also a runtime optimization. Clang is extremely efficient at simplying code down so long as it can evaluate conditions at compile time. In my test case, LLVM was able to simplify the machine code to two variable allocations and a number literal return at compile time when I did not use variables.

In our case, we are not going to directly simplify our AST prior to code generation. We are however going to evaluate all literal nodes that the AST is able to resolve at compile time via a value resolution pass. Where a value resolution can not be completed at compile time, a LLVM value will be resolved instead such that it can be used as a reference in the parent's nodes resolution phase. We can likely still benefit from LLVM optimizations on the outputted IR regardless of our approach. Feel free to experiment with simplifying your AST prior to code generation if you want to take the example compiler further.

One last thing you will need to be aware of. Because our toy example will eventually allow control flow, multiple blocks, and functions, we must use LLVM space to store and load variable's values. LLVM must resolve a variables value to ensure that the proper code blocks either executed or not based on the control flow of the program. We possibly could evaluate the value at compile time in some cases but this would greatly increase the complexity of the compiler. Instead we will play it safe and look up all variables from llvm. 