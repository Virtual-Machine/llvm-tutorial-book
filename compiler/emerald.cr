require "./types"
require "./token"
require "./lexer"
require "./node"
require "./parser"
require "./generator"

# Toggle debug information
debug = true

# Emerald expression as input
input = "puts \"Hello World!\""

# Lex input into token array
lexer = Lexer.new input
lexer.lex

lexer.inspect if debug

# Parse token array into AST
parser = Parser.new lexer.tokens
parser.parse

parser.inspect if debug

# Use AST to generate LLVM IR
generator = Generator.new parser.ast
generator.generate

generator.inspect if debug

# Print output
output = generator.output
puts output
