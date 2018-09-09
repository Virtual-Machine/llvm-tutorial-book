require "llvm"

class Program
  getter main : LLVM::BasicBlock, mod : LLVM::Module, builder : LLVM::Builder
  getter! func : LLVM::Function

  def initialize
    # Create the context
    context = LLVM::Context.new

    # Create a module
    @mod = context.new_module("name")

    # Add a global number variable "number" = 10
    mod.globals.add context.int32, "number"
    mod.globals["number"].initializer = context.int32.const_int(10)

    # Create a main function
    @func = mod.functions.add "main", ([] of LLVM::Type), context.int32

    # Create body for main function - builder appends to basic blocks.
    @main = func.basic_blocks.append "main_body"

    # Make main function externally linkable
    func.linkage = LLVM::Linkage::External

    # Declare external function puts
    mod.functions.add "puts", [context.void_pointer], context.int32

    # Initialize Crystal's builder API
    @builder = context.new_builder
  end

  def code_generate
    # Before calling builder, you must position it into the active basic block of your program
    builder.position_at_end main

    # While walking the AST nodes you can call builder API to generate instructions into the basic block...
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
