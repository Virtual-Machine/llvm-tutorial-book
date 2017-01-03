require "./types"
require "./token"
require "./lexer"
require "./node"
require "./nodes/*"
require "./parser"
require "./generator"

# Toggle debug information
debug_lexer = true
debug_parser = true
debug_generator = true

# Emerald expression as input
input = "puts \"Hello World!\""

# Lex input into token array
lexer = Lexer.new input
lexer.lex

lexer.inspect if debug_lexer

# Parse token array into AST
parser = Parser.new lexer.tokens
parser.parse

parser.inspect if debug_parser

# Use AST to generate LLVM IR
generator = Generator.new parser.ast
generator.generate

generator.inspect if debug_generator

# Print output
output = generator.output
puts output
