require "./types"
require "./token"
require "./node"
require "./lexer"
require "./parser"
require "./state"
require "./instruction"

require "llvm"

class EmeraldProgram
  getter input_code, token_array, ast, output, delimiters, state, mod, builder, options, main : LLVM::BasicBlock
  getter! lexer, parser, func : LLVM::Function

  def initialize(@input_code : String)
    @options = {
      "color"             => true,
      "supress"           => false,
      "printTokens"       => false,
      "printAST"          => false,
      "printResolutions"  => false,
      "printInstructions" => false,
      "printOutput"       => false,
      "filename"          => "",
    }
    @token_array = [] of Token
    @ast = [] of Node
    @output = ""
    @state = ProgramState.new
    @mod = LLVM::Module.new("Emerald")
    @func = mod.functions.add "main", ([] of LLVM::Type), LLVM::Int32
    func.linkage = LLVM::Linkage::External
    @main = func.basic_blocks.append "main_body"
    @builder = LLVM::Builder.new
    state.add_function "main", func
    state.add_function "puts", mod.functions.add "puts", [LLVM::VoidPointer], LLVM::Int32
  end

  def initialize(@options : Hash(String, (String | Bool)))
    @input_code = File.read(@options["filename"].as(String))
    @token_array = [] of Token
    @ast = [] of Node
    @output = ""
    @state = ProgramState.new
    @mod = LLVM::Module.new("Emerald")
    @func = mod.functions.add "main", ([] of LLVM::Type), LLVM::Int32
    func.linkage = LLVM::Linkage::External
    @main = func.basic_blocks.append "main_body"
    @builder = LLVM::Builder.new
    state.add_function "main", func
    state.add_function "puts", mod.functions.add "puts", [LLVM::VoidPointer], LLVM::Int32
  end

  def lex : Nil
    @lexer = Lexer.new input_code
    @token_array = lexer.lex
    if options["printTokens"]
      puts options["color"] ? "\033[032mTOKENS\033[039m" : "TOKENS"
      @token_array.each do |token|
        puts token
      end
      puts
    end
  end

  def parse : Nil
    @parser = Parser.new token_array
    @ast = parser.parse
  end

  def generate : Nil
    # Add debug values to state
    state.printAST = options["printAST"].as(Bool)
    state.printResolutions = options["printResolutions"].as(Bool)
    if state.printAST || state.printResolutions
      puts options["color"] ? "\033[032mAST / RESOLUTIONS\033[039m" : "AST / RESOLUTIONS"
    end

    # Walk nodes to resolve values and generate state
    @ast[0].walk state

    if state.printAST || state.printResolutions
      puts
    end

    # Use state instructions to generate LLVM IR
    build_instructions

    # Output LLVM IR to output.ll
    output
  end

  def build_instructions : Nil
    builder.position_at_end main
    # If last instruction is not a return instruction, add ret i32 0 to close main
    if state.instructions[-1].class != ReturnInstruction
      state.add_instruction ReturnInstruction.new 0, "Int32", "return"
    end
    puts options["color"] ? "\033[032mINSTRUCTIONS\033[039m" : "INSTRUCTIONS" if options["printInstructions"]
    state.instructions.each do |instruction|
      puts instruction if options["printInstructions"]
      instruction.build_instruction builder
    end
    puts
  end

  def output : String
    if !options["supress"]
      File.open("output.ll", "w") do |file|
        mod.to_s(file)
      end
    end
    if options["printOutput"]
      puts options["color"] ? "\033[032mOUTPUT\033[039m" : "OUTPUT"
      puts mod.to_s
      puts
    end
    @output = mod.to_s
  end

  def compile : Nil
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
