#Example Clang

These files are used as examples in Chapter 4 and 5 when using Clang to inspect how it translates C into an AST and subsequent LLVM IR.

### Dump AST
```bash
clang -cc1 -ast-dump name_of_file.c
```


### Emit LLVM IR
```bash
clang -cc1 -emit-llvm name_of_file.c
```


