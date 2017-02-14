#Chapter 8 Function Declarations

Now that our toy language can use logic to control what portions of code will run based on specified conditions we can write much more interesting programs. But we may find that our code is very long winded and hard to understand when its all crammed into one main function. Many programmers like to refactor blocks of repeated code into their own functions to aid readability. Also due to our example language being statically typed, functions allow the compiler to check the types of parameters and issue helpful errors when a parameter does not match the expected type.

Therefore, we know that functions are going to be a useful tool for our language. The question remains however, how will we implement them? The good news is, based on what we have written for our compiler so far, implementing functions is pretty straight forward. Much like we needed the ability to monitor active blocks when we implemented if/else statements, to parse function declarations we require the ability to get and set the active function in our module. The state class therefore will concern itself with both active function and active block and ensure that instructions are always appended to the correct location in the module. 

The other concern we now have is, how are we going to designate the function signature? A function signature is actually a pretty simple idea, we merely need to know how many parameters a function can take, what type each parameter is, and what type of value the function returns. In Crystal for example if we wanted a function that takes two integers and returns their sum we might end up with a function like the following:

```crystal
def add_x_and_y(x : Int32, y : Int32) : Int32
    return x + y
end
```

Right in the function definition we can see this function takes two parameters, each of type Int32, and returns an Int32. Therefore if we later call add_x_and_y with anything but 2 parameters of type Int32 the compiler will tell us and we can hopefully find the issue quickly and resolve it. Also based on the return type of this function, we can safely take the product of this function and use it as an Int32 knowing the compiler is enforcing this.

For our toy language, our syntax will be similar however we will not use a colon to seperate our types from our parameters. This should not interfere with parsing but feel free to implement a seperator token if you find the need for them. Therefore the same function in Emerald would read as follows:

```crystal
def add_x_and_y(x Int32, y Int32) Int32
    return x + y
end
```

The def keyword will be the key to putting this together. When the compiler detects the def keyword, it knows that it is now parsing a function declaration. It will resolve the parameters and their types as well as the return type, and then use this to inject a function into the module with the correct function signature. It then resolves the instructions in the function body to the newly active function, completing the function definition. When the parser reaches the end of the function definition, the main function is once again made active and the parsing continues.

Later when this function identifier is used again, it will be identified as a call expression, and the compiler will call its internal representation of the function with the provided parameters. Assuming the correct number and types of parameters are given, the function will return the expected result. Therefore, the compiler needs to look up all indentifiers to determine if they are a function or a variable. In our implementation, if an identifier is both a function and a variable, it will be treated only as a function so care is needed for naming functions and variables. In particular, it would be impossible to determine a no parameter function from a variable based on our syntax so it is recommended that you simply use differing names to avoid the confusion.