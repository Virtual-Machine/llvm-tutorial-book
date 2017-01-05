class Node
  getter children
  property parent
  @children = [] of Node
  @parent : Node?

  def add_child(node : Node)
    @children.push(node)
    node.parent = self
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
