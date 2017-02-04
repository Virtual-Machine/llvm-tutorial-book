require "./types"
require "./error"
require "./token"
require "./nodes/node.cr"
require "./nodes/*"
require "./lexer"
require "./verifier"
require "./parser"
require "./state"
require "./close_statements"

require "llvm"

class EmeraldProgram
  getter input_code, token_array, ast, output, delimiters, state, mod, builder, options, verifier, main : LLVM::BasicBlock
  getter! lexer, parser, func : LLVM::Function

  def self.new_from_input(input : String, test_mode : Bool = false)
    options = {
      "color"             => true,
      "supress"           => false,
      "printTokens"       => false,
      "printAST"          => false,
      "printResolutions"  => false,
      "printInstructions" => false,
      "printOutput"       => false,
      "optimize"          => false,
      "filename"          => "",
    }
    self.new input, options, test_mode
  end

  def self.new_from_options(options : Hash(String, (String | Bool)), test_mode : Bool = false)
    input = File.read(options["filename"].as(String))
    self.new input, options, test_mode
  end

  def initialize(@input_code : String, @options : Hash(String, (String | Bool)), @test_mode : Bool = false)
    @token_array = [] of Token
    @ast = [] of Node
    @output = ""
    @verifier = Verifier.new
    @mod = LLVM::Module.new("Emerald")
    @func = mod.functions.add "main", ([] of LLVM::Type), LLVM::Int32
    @main = func.basic_blocks.append "main_body"
    @builder = LLVM::Builder.new
    @state = ProgramState.new builder, mod, main
  end

  def lex : Nil
    @lexer = Lexer.new input_code
    @token_array = lexer.lex
    if options["printTokens"]
      puts options["color"] ? "\033[032mTOKENS\033[039m" : "TOKENS"
      @token_array.each do |token|
        puts token.to_s
      end
      puts
    end
    begin
      verifier.verify_token_array @token_array
    rescue ex : EmeraldSyntaxException
      ex.full_error @input_code, @options["color"].as(Bool), @test_mode
    end
  end

  def parse : Nil
    @parser = Parser.new token_array
    begin
      @ast = parser.parse
    rescue ex : EmeraldSyntaxException
      ex.full_error @input_code, @options["color"].as(Bool), @test_mode
    end
  end

  def generate : Nil
    # Add debug values to state
    state.printAST = options["printAST"].as(Bool)
    state.printResolutions = options["printResolutions"].as(Bool)
    if state.printAST || state.printResolutions
      puts options["color"] ? "\033[032mAST / RESOLUTIONS\033[039m" : "AST / RESOLUTIONS"
    end

    # Walk nodes to resolve values and generate llvm ir
    begin
      @ast[0].walk state
      state.close_blocks
    rescue ex : EmeraldSyntaxException
      ex.full_error @input_code, @options["color"].as(Bool), @test_mode
    end

    if state.printAST || state.printResolutions
      puts
    end

    # Run standard optimizations on module if enabled
    if @options["optimize"]
      fun_pass_manager = mod.new_function_pass_manager
      pass_manager_builder = begin
        registry = LLVM::PassRegistry.instance
        registry.initialize_all

        builder = LLVM::PassManagerBuilder.new
        builder.opt_level = 3
        builder.size_level = 0
        builder.use_inliner_with_threshold = 275
        builder
      end
      pass_manager_builder.populate fun_pass_manager
      fun_pass_manager.run mod
    end

    # Output LLVM IR to output.ll
    output
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

# program = EmeraldProgram.new_from_input input
# program.compile
# puts program.output
