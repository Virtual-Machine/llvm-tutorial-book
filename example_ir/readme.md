#Example IR

These examples are meant to help you see simple llvm ir in action and get a feel for how it works.

For each file
```bash
llc file.ll #yields file.s assembly file
clang file.s -o main #compiles assembly to machine code
```

A helpful tool for examining simplified Crystal to llvm-ir
```
crystal build file.cr --emit llvm-ir --prelude=empty
```
