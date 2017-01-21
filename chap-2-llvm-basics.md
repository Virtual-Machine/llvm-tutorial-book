#Chapter 2 LLVM Basics

This chapter is a crash course in LLVM's most basic concepts and terminologies. This is by no means complete, but it will be enough to give you a decent idea of how LLVM works and how you will be using its api.

First and foremost, we will be putting some blinders on and using LLVM in a very simplistic way. Despite the fact that LLVM exposes a very detailed modular api with lots of control at all stages of code compilation, we are going to take a very lazy, and in some cases perhaps even naive approach, to working with it. That is ok for now because A) its more rewarding to get to a working stage quickly, and B) LLVM has lots of tooling that will make our naive code run plenty efficiently for the time being. Once we understand the basics, then we can begin to add more advanced techniques to our approach.

So what do I mean by us taking a lazy approach? What I mean is we are going to let the LLVM ir builder api do the heavy lifting for us and we are not going to spend much, if any, time tinkering with the generated ir other than applying the standard optimizations LLVM offers. This means if our lexer and parser can generate an AST of nodes that the LLVM ir builder api understands, we are essentially done. The only remaining work will be to call the builder api wth the correct references to each of our nodes.

So what do I mean by us taking a naive approach? Full disclaimer, I am very much still a student of compilers and LLVM, I am probably doing many things that a compiler/LLVM expert would consider naive or ignorant. Also in the interest of enlightening people without adding unnecessary confusion I will be trying to keep things extremely simplistic. This means I will try to avoid using lots of indirection, complex abstractions, inheritance, and implicit behaviour in the compiler even if the end result is more verbose code. The code may not follow all the best practices but it will be easy to read and understand.

### General LLVM Information

Here are some gross simplications that should help you get started with LLVM. Fill your knowledge in with more details as it becomes necessary.

1. The main unit of grouping in LLVM is the module. You can have several modules in a program, and each module will contain functions, global variables and an externalized interface. In our simplistic, naive approach we will never use more than one module but know that it is possible.
2. Everything inside a module is a llvm Value descendent. These include but are not limited to functions, blocks, expressions, instructions, etc... A nice way to visually think of this is: **Module** can have **Functions** which have one or more **BasicBlock** which is made up of **Instructions**. Values are a way for each component to reference each other and is the basis for compile time mathematic calculations.
3. BasicBlocks are an important concept. BasicBlocks are the cornerstone of the ir builder API and for good reason. A BasicBlock is simply a list of instructions in which the only way they can be executed is from first to last in order with no control flow. Think of a function body with no logic statements or gotos and you are likely looking at a BasicBlock.
4. A function is basically a block of code that accepts a given list of typed parameters and returns a typed value. LLVM views it the same way. We will be initially running all our code inside a main function that we will initialize by giving it a C main interface. A simplified C main function takes no parameters and returns an integer. Therefore in LLVM we say that it will take an empty array of LLVM type values, and return a LLVM 32 bit integer.
5. LLVM type values are exactly what they sound like, it is LLVMs internal representation of type as related to an LLVM Value object. This is the system where by your code can be statically typed and compiled to object code callable from C. By giving our main function a C interface using LLVM types, and by flagging our main function as a LLVM::Linkage::External we have allowed linkers to identify our object code's main function as if it were compiled from C.
6. The LLVM builder api has the notion of position. A given builder has to be directed where it will be appending new instructions. In the case of our initial simplified approach we will be appending all our instructions to the BasicBlock of the main function. As you can imagine this sets up the primary means of constructing function bodies across multiple functions in a module. To add control flow, loops, and more functions we need to track the basic blocks of our module and append the instructions into the correct blocks.
7. Finally once you are finished compiling the instructions into your module, you will want to dump the output to LLVM IR ll files. The resultant [name_of_file].ll can now be treated like any LLVM IR as if it were just compiled straight from C. This includes all the optimizations and plugins available in the LLVM architecture. It is also ready to be compiled to object code and linked with any other object code compiled from other sources. The file.ll theoretically can be compiled to any target architecture so long as the LLVM IR is not doing anything machine specific.
8. Because our example is compiling instructions into a main function, if we execute the compiled and linked version of our output (aka the machine binary), it should immediately invoke the main function and we should see the results of our instructions.
9. LLVM is a low level machine, therefore it doesn't have high level types by default. There is however nothing stopping you from adding your own types as aliases or struct combinations of low level builtin types. In our toy example we will not make much use of this power but know that it exists and can be used to create more powerful containers for values, for example like Crystal's or C++'s string type. In our example we will simply treat strings like C strings, terminated by a null byte, which LLVM treats as an i8* (8 bit integer pointer). This means that all string values in our program will be global string values, passed by pointer.


### LLVM IR instructions

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

;icmp - compare two integer values with a given operator
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

### Crystal LLVM Builder API Bindings

We are using Crystal's builder API bindings to LLVM and as such we also need to have an idea of how to use the builder API to assemble modules. Below is a generic program class that demonstrates how to use the builder api in a simplistic way. Once you grasp this, you should be able to see how you can direct the builder api into different blocks and functions throughout your module as needed.

```crystal
require "llvm"

class Program
  getter mod, builder, main : LLVM::BasicBlock
  getter! func : LLVM::Function

  def initialize
    # create a module
    @mod = LLVM::Module.new("module_name")
    
    # add a global number variable "number" = 10
    mod.globals.add LLVM::Int32, "number"
    mod.globals["number"].initializer = LLVM.int LLVM::Int32, 10
    
    # create a main function
    @func = mod.functions.add "main", ([] of LLVM::Type), LLVM::Int32
    
    # create body for main function - builder appends to basic blocks.
    @main = func.basic_blocks.append "main_body"

    # make main function externally linkable
    func.linkage = LLVM::Linkage::External

    # declare external function puts
    mod.functions.add "puts", [LLVM::VoidPointer], LLVM::Int32
    
    # initialize Crystal's builder api
    @builder = LLVM::Builder.new
  end

  def code_generate
    # Before calling builder, you must position it into the active basic block of your program
    builder.position_at_end main
    # While walking the AST nodes you can call builder api to generate instructions into the basic block...
    str_ptr = builder.global_string_pointer "Johnny", "str"
    builder.call mod.functions["puts"], str_ptr, "str_call"
    num_val = builder.load mod.globals["number"]
    builder.ret num_val

    File.open("output.ll", "w") do |file|
      mod.to_s(file)
    end
  end
end

program = Program.new
program.code_generate

```

It is the relationship between your AST nodes and your code generation functions that the final module will get built. Therefore you should spend time walking the nodes of your AST and thinking about what builder api calls you will need to accomplish the functionality you desire in LLVM IR.

### Builder API Usage

Below is a list of builder methods with short descriptions. A few of the ones you'll find especially useful have demonstration usages provided.
```crystal
#add(lhs, rhs, name = "") add two values together and return sum value

    value = builder.add(four_val, five_val, "4_plus_5")

#alloca(type, name = "") allocate space for given variable type

    value = builder.alloca(LLVM::Int32, "number")

#and(lhs, rhs, name = "") perform bitwise and operation
#array_malloc(type, value, name = "")
#ashr(lhs, rhs, name = "") perform bitwise right hand shift
#atomicrmw(op, ptr, val, ordering, singlethread) atomically modify memory
#bit_cast(value, type, name = "") convert value to type2 without changing bits
#br(block) unconditional branch to block

    builder.br(block_ref)

#call(func, args : Array(LLVM::Value), name : String = "") call a multi parameter function
#call(func, arg : LLVM::Value, name : String = "") call a single param function

    ret_value = builder.call mod.functions["puts"], str_ptr, "puts_call"

#call(func, name : String = "") call a no parameter function
#cmpxchg(pointer, cmp, new, success_ordering, failure_ordering) atomically modify memory based on comparison
#cond(cond, then_block, else_block) conditional branch to block

    builder.cond if_value, then_block_ref, else_block_ref

#exact_sdiv(lhs, rhs, name = "") performs division using exact keyword, result is poison value if rounding would occur
#extract_value(value, index, name = "") extracts value from aggregate object
#fadd(lhs, rhs, name = "") floating point and vector addition
#fcmp(op, lhs, rhs, name = "") floating point comparison
#fdiv(lhs, rhs, name = "") floating point division
#fence(ordering, singlethread, name = "") introduces edges between operations
#fmul(lhs, rhs, name = "") floating point multiplication
#fp2si(value, type, name = "") floating point to signed int
#fp2ui(value, type, name = "") floating point to unsigned int
#fpext(value, type, name = "") floating point extension
#fptrunc(value, type, name = "") floating point truncation
#fsub(lhs, rhs, name = "") floating point subtraction
#gep(value, index1 : LLVM::Value, index2 : LLVM::Value, name = "") get element pointer returns a subelement of a container using start, end indices
#gep(value, index : LLVM::Value, name = "") get element pointer returns a subelement of a container using a start index
#gep(value, indices : Array(LLVM::ValueRef), name = "") get element pointer returns a sub element using an indices array
#global_string_pointer(string, name = "") generate global string constant pointer
    
    string_ptr = builder.global_string_pointer("Hello World", "example")

#icmp(op, lhs, rhs, name = "") integer comparison operation
    
    result = builder.icmp(LLVM::IntPredicate::ULT, ten_val, nine_val, "comparison")

#inbounds_gep(value, indices : Array(LLVM::ValueRef), name = "") gep with inbounds keyword
#inbounds_gep(value, index1 : LLVM::Value, index2 : LLVM::Value, name = "") gep with inbounds keyword
#inbounds_gep(value, index : LLVM::Value, name = "") gep with inbounds keyword
#int2ptr(value, type, name = "") convert integer to pointer type
#invoke(fn, args : Array(LLVM::Value), a_then, a_catch, name = "") allows exception handling by returning to then block unless exception is detected and then instead returns to catch block
#landing_pad(type, personality, clauses, name = "") designates a basic block as where an exception is handled inside a catch routine
#load(ptr, name = "") get the value stored in a pointer

    value = builder.load(ptr_to_value, "value_in_ptr")

#lshr(lhs, rhs, name = "") performs a logical right hand shift operation
#mul(lhs, rhs, name = "") perform multiplication
#not(value, name = "")
#or(lhs, rhs, name = "") performs bitwise or operation

#phi(type, table : LLVM::PhiTable, name = "") setup phi node based on preexisting table data

#NOTE a phi node is simply a variable that takes on a value based on the preceding block that passed control to the phi node.

#phi(type, incoming_blocks : Array(LLVM::BasicBlock), incoming_values : Array(LLVM::Value), name = "") setup phi node based on array of basic blocks and an array of the values it should take in each case

#position_at_end(block) position builder at end of a given block
#ptr2int(value, type, name = "") resolve integer pointer to int
#ret(value) return a specified value

    builder.ret (LLVM.int (LLVM::Int32, 0))

#ret return void
#sdiv(lhs, rhs, name = "") signed integer division
#select(cond, a_then, a_else, name = "") select a value based on a condition
#sext(value, type, name = "") signed extension
#shl(lhs, rhs, name = "") shift left expression
#si2fp(value, type, name = "") cast signed integer to floating point
#srem(lhs, rhs, name = "") return remainder of signed integer division
#store(value, ptr) store value into pointer

    builder.store four_val, number_ptr

#sub(lhs, rhs, name = "") integer subtraction
#switch(value, otherwise, cases) allow branching to one of several branches based on value
#trunc(value, type, name = "") truncating integer
#udiv(lhs, rhs, name = "") unsigned division
#ui2fp(value, type, name = "") unsigned integer to floating point
#urem(lhs, rhs, name = "") unsigned division remainder
#xor(lhs, rhs, name = "") bitwise logical xor operation
#zext(value, type, name = "") zero extension
```

Further Reading and References:

1. [LLVM for Grad Students by Adrian Sampson](https://www.cs.cornell.edu/~asampson/blog/llvm.html)

2. [How to get started with the LLVM C API by Paul Smith](https://pauladamsmith.com/blog/2015/01/how-to-get-started-with-llvm-c-api.html)

3. [Create a working compiler with the LLVM framework, Part 1 by Arpen Sen](https://www.ibm.com/developerworks/library/os-createcompilerllvm1/)

4. [My First LLVM Compiler by Wilfred Hughes](http://www.wilfred.me.uk/blog/2015/02/21/my-first-llvm-compiler/)
