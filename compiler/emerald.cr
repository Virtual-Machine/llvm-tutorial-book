require "./types"
require "./token"
require "./lexer"
require "./node"
require "./parser"
require "./generator"

# Emerald expression as input
input = "puts \"Hello World!\""

# Lex input into token array
lexer = Lexer.new input
lexer.lex

lexer.inspect

# Parse token array into AST
parser = Parser.new lexer.tokens
parser.parse

parser.inspect

# Use AST to generate LLVM IR
generator = Generator.new parser.ast
generator.generate

generator.inspect

# Print output
output = generator.output
pp output
