require "llvm"
require "./demo_ast"
require "./state"

class Program
  getter mod, builder, nodes, state
  property active
  getter! func : LLVM::Function

  def initialize(@nodes : Node)
    @mod = LLVM::Module.new("test")
    @func = mod.functions.add "main", ([] of LLVM::Type), LLVM::Int32
    func.linkage = LLVM::Linkage::External
    mod.functions.add "puts", [LLVM::VoidPointer], LLVM::Int32
    @builder = LLVM::Builder.new
    @state = State.new
    @active = "main"
  end

  def compile
    nodes.walk self

    # pp state

    # # Calculate equation and perform comparison
    # multiple = builder.mul three, four, "multiple"
    # sum = builder.add two, multiple, "sum"
    # less_than = LLVM::IntPredicate::SGT
    # comparison = builder.icmp less_than, sum, four, "comparison"
    # builder.cond comparison, if_block, else_block
    # # If 2 + 3 * 4 < 3
    # builder.position_at_end if_block
    # builder.store two, number_ptr
    # builder.br return_block
    # # Else
    # builder.position_at_end else_block
    # builder.store five, number_ptr
    # builder.br return_block
    # # Return
    # builder.position_at_end return_block
    # ret_value = builder.load number_ptr, "ret_value"
    # builder.ret ret_value

    File.open("output.ll", "w") do |file|
      mod.to_s(file)
    end
  end
end

program = Program.new AST.demo
program.compile
