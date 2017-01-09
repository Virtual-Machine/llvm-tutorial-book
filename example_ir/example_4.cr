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

    File.open("example_4.ll", "w") do |file|
      mod.to_s(file)
    end
  end
end

program = Program.new
program.code_generate