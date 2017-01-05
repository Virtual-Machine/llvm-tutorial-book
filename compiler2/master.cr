require "llvm"

class Node
  getter children
  @children = [] of Node

  def add_child(node : Node)
    @children.push(node)
  end

  def walk(bb : LLVM::BasicBlock)
    @children.each do |node|
      pp node
      node.walk bb
    end
  end
end

class StringLiteralNode < Node
  getter value

  def initialize(@value : String)
  end
end

class IntegerLiteralNode < Node
  getter value

  def initialize(@value : Int32)
  end
end

class DoubleLiteralNode < Node
  getter value

  def initialize(@value : Float64)
  end
end

class BooleanLiteralNode < Node
  getter value

  def initialize(@value : Bool)
  end
end

class FunctionDeclarationNode < Node
  def initialize(@name : String, @signature : String)
  end
end

class CompoundStatementNode < Node
end

class DeclarationStatementNode < Node
end

class VariableDeclarationNode < Node
  def initialize(@name : String, @type : String)
  end
end

class IfStatementNode < Node
end

class BinaryOperatorNode < Node
  def initialize(@operator : String)
  end
end

class ImplicitCastExpressionNode < Node
  def initialize(@type : String)
  end
end

class DeclarationReferenceExpressionNode < Node
  def initialize(@name : String)
  end
end

class ReturnStatementNode < Node
end

ast = Node.new
main = FunctionDeclarationNode.new "main", "int ()"
main_body = CompoundStatementNode.new
declare1 = DeclarationStatementNode.new
number_decl = VariableDeclarationNode.new "number", "int"
declare2 = DeclarationStatementNode.new
two_decl = VariableDeclarationNode.new "two", "int"
two_literal = IntegerLiteralNode.new 2
three_decl = VariableDeclarationNode.new "three", "int"
three_literal = IntegerLiteralNode.new 3
four_decl = VariableDeclarationNode.new "four", "int"
four_literal = IntegerLiteralNode.new 4
if_statement = IfStatementNode.new
compare = BinaryOperatorNode.new "<"
add = BinaryOperatorNode.new "+"
implicit_cast1 = ImplicitCastExpressionNode.new "int"
variable_ref1 = DeclarationReferenceExpressionNode.new "two"
multiply = BinaryOperatorNode.new "*"
implicit_cast2 = ImplicitCastExpressionNode.new "int"
variable_ref2 = DeclarationReferenceExpressionNode.new "three"
implicit_cast3 = ImplicitCastExpressionNode.new "int"
variable_ref3 = DeclarationReferenceExpressionNode.new "four"
implicit_cast4 = ImplicitCastExpressionNode.new "int"
variable_ref4 = DeclarationReferenceExpressionNode.new "three"
if_body = CompoundStatementNode.new
set_value1 = BinaryOperatorNode.new "="
variable_ref5 = DeclarationReferenceExpressionNode.new "number"
implicit_cast6 = ImplicitCastExpressionNode.new "int"
variable_ref6 = DeclarationReferenceExpressionNode.new "two"
else_body = CompoundStatementNode.new
set_value2 = BinaryOperatorNode.new "="
variable_ref7 = DeclarationReferenceExpressionNode.new "number"
five_literal = IntegerLiteralNode.new 5
return_stmt = ReturnStatementNode.new
implicit_cast8 = ImplicitCastExpressionNode.new "int"
variable_ref8 = DeclarationReferenceExpressionNode.new "number"

ast.add_child main
main.add_child main_body
main_body.add_child declare1
main_body.add_child declare2
main_body.add_child if_statement
main_body.add_child return_stmt
declare1.add_child number_decl
declare2.add_child two_decl
declare2.add_child three_decl
declare2.add_child four_decl
two_decl.add_child two_literal
three_decl.add_child three_literal
four_decl.add_child four_literal
if_statement.add_child compare
if_statement.add_child if_body
if_statement.add_child else_body
compare.add_child add
compare.add_child implicit_cast4
add.add_child implicit_cast1
add.add_child multiply
implicit_cast1.add_child variable_ref1
multiply.add_child implicit_cast2
implicit_cast2.add_child variable_ref2
multiply.add_child implicit_cast3
implicit_cast3.add_child variable_ref3
implicit_cast4.add_child variable_ref4
if_body.add_child set_value1
set_value1.add_child variable_ref5
set_value1.add_child implicit_cast6
implicit_cast6.add_child variable_ref6
else_body.add_child set_value2
set_value2.add_child variable_ref7
set_value2.add_child five_literal
return_stmt.add_child implicit_cast8
implicit_cast8.add_child variable_ref8

class Program
  getter mod, builder, nodes
  getter! func : LLVM::Function

  def initialize(@nodes : Node)
    @mod = LLVM::Module.new("test")
    @func = mod.functions.add "main", ([] of LLVM::Type), LLVM::Int32
    func.linkage = LLVM::Linkage::External
    mod.functions.add "putchar", [LLVM::Int32], LLVM::Int32
    @builder = LLVM::Builder.new
  end

  def compile
    # Set up blocks for function
    bb = func.basic_blocks.append "main_body"
    if_block = func.basic_blocks.append "if_block"
    else_block = func.basic_blocks.append "else_block"
    return_block = func.basic_blocks.append "return_block"

    builder.position_at_end bb
    # Variable to store number value
    number_ptr = builder.alloca LLVM::Int32, "number"
    # LLVM friendly integers
    zero = LLVM.int(LLVM::Int32, 0)
    two = LLVM.int(LLVM::Int32, 2)
    three = LLVM.int(LLVM::Int32, 3)
    four = LLVM.int(LLVM::Int32, 4)
    five = LLVM.int(LLVM::Int32, 5)

    # Calculate equation and perform comparison
    multiple = builder.mul three, four, "multiple"
    sum = builder.add two, multiple, "sum"
    less_than = LLVM::IntPredicate::SGT
    comparison = builder.icmp less_than, sum, four, "comparison"
    builder.cond comparison, if_block, else_block
    # If 2 + 3 * 4 < 3
    builder.position_at_end if_block
    builder.store two, number_ptr
    builder.br return_block
    # Else
    builder.position_at_end else_block
    builder.store five, number_ptr
    builder.br return_block
    # Return
    builder.position_at_end return_block
    ret_value = builder.load number_ptr, "ret_value"
    builder.ret ret_value

    File.open("output.ll", "w") do |file|
      mod.to_s(file)
    end
  end
end

program = Program.new ast
program.compile
