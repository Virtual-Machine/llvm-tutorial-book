require "./types"
require "./token"
require "./node"
require "./lexer"
require "./parser"
require "./state"
require "./instruction"

require "llvm"

class EmeraldProgram
  getter lexer, parser, input_code, token_array, ast, output, delimiters, state, mod, builder, main : LLVM::BasicBlock
  getter! func : LLVM::Function

  def initialize(@input_code : String)
    @token_array = [] of Token
    @ast = [] of Node
    @output = ""
    @lexer = Lexer.new ""
    @state = ProgramState.new
    @mod = LLVM::Module.new("Emerald")
    @func = mod.functions.add "main", ([] of LLVM::Type), LLVM::Int32
    func.linkage = LLVM::Linkage::External
    @main = func.basic_blocks.append "main_body"
    @builder = LLVM::Builder.new
    state.add_function "main", func
    state.add_function "puts", mod.functions.add "puts", [LLVM::VoidPointer], LLVM::Int32
  end

  def lex
    @lexer = Lexer.new input_code
    @token_array = lexer.lex
  end

  def parse
    @parser = Parser.new token_array
    @ast = parser.not_nil!.parse
  end

  def generate
    @ast[0].walk state

    builder.position_at_end main

    state.instructions.each do |instruction|
      instruction.build_instruction builder
    end

    # This should only be called if input source doesn't contain explicit return statement
    # Requires a specific check during the ast walking stage to be implemented
    builder.ret LLVM.int(LLVM::Int32, 0)

    # To output an output.ll file ready to be converted to native assembly with llc
    File.open("output.ll", "w") do |file|
      mod.to_s(file)
    end

    # Store output for later inspection
    @output = mod.to_s
  end

  def compile
    lex
    parse
    generate
  end
end

# input = "# I am a comment!
# four = 2 + 2
# puts four
# puts 10 < 6
# puts 11 != 10
# "

# program = EmeraldProgram.new input
# program.compile
# puts program.output
