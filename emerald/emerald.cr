require "./types"
require "./token"
require "./node"
require "./lexer"
require "./parser"

class EmeraldProgram
  getter lexer, parser, input_code, token_array, ast, output, delimiters

  def initialize(@input_code : String)
    @token_array = [] of Token
    @ast = [] of Node
    @output = ""
    @lexer = Lexer.new ""
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
    @ast[0].walk
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
