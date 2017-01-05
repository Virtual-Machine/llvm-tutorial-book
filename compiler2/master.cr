require "llvm"

count = -1

def get_pad(count : Int32)
  "\t" * count
end

class Node
  getter children
  @children = [] of Node

  def add_child(node : Node)
    @children.push(node)
  end

  def walk(count : Int32)
    count += 1
    @children.each do |node|
      node.walk count
    end
  end
end

class StringLiteralNode < Node
  getter value

  def initialize(@value : String)
  end

  def walk(count : Int32)
    puts "#{get_pad count}#{value}"
  end
end

class IntegerLiteralNode < Node
  getter value

  def initialize(@value : Int32)
  end

  def walk(count : Int32)
    puts "#{get_pad count}#{value}"
  end
end

class DoubleLiteralNode < Node
  getter value

  def initialize(@value : Float64)
  end

  def walk(count : Int32)
    puts "#{get_pad count}#{value}"
  end
end

class BooleanLiteralNode < Node
  getter value

  def initialize(@value : Bool)
  end

  def walk(count : Int32)
    puts "#{get_pad count}#{value}"
  end
end

class FunctionDeclarationNode < Node
  def initialize(@name : String, @signature : String)
  end

  def walk(count : Int32)
    puts "#{get_pad count}#{@name}, #{@signature}"
    super count
  end
end

class CompoundStatementNode < Node
  def walk(count : Int32)
    puts "#{get_pad count}Compound"
    super count
  end
end

class DeclarationStatementNode < Node
  def walk(count : Int32)
    puts "#{get_pad count}Declaration"
    super count
  end
end

class VariableDeclarationNode < Node
  def initialize(@name : String, @type : String)
  end

  def walk(count : Int32)
    puts "#{get_pad count}Declare: #{@name}, #{@type}"
    super count
  end
end

class IfStatementNode < Node
  def walk(count : Int32)
    puts "#{get_pad count}If"
    super count
  end
end

class BinaryOperatorNode < Node
  def initialize(@operator : String)
  end

  def walk(count : Int32)
    puts "#{get_pad count}#{@operator}"
    super count
  end
end

class ImplicitCastExpressionNode < Node
  def initialize(@type : String)
  end

  def walk(count : Int32)
    puts "#{get_pad count}#{@type}"
    super count
  end
end

class DeclarationReferenceExpressionNode < Node
  def initialize(@name : String)
  end

  def walk(count : Int32)
    puts "#{get_pad count}#{@name}"
    super count
  end
end

class ReturnStatementNode < Node
  def walk(count : Int32)
    puts "#{get_pad count}Return"
    super count
  end
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
    bb = func.basic_blocks.append "entry"
    # Walk ast and code generate to bb
    File.open("output.ll", "w") do |file|
      mod.to_s(file)
    end
  end
end

ast.walk count

# program = Program.new ast
# program.compile
