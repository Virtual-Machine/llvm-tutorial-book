class Node
  getter children
  property parent
  @children = [] of Node
  @parent : Node?

  def add_child(node : Node)
    @children.push(node)
    node.parent = self
  end

  def walk(prog : Program)
    @children.each do |node|
      puts node
      node.pre_walk prog
      node.walk prog
      node.post_walk prog
    end
  end

  def pre_walk(prog : Program)
  end

  def post_walk(prog : Program)
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

  def pre_walk(prog : Program)
    prog.state.add_integer value
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
  getter name

  def initialize(@name : String, @signature : String)
  end

  def pre_walk(prog : Program)
    prog.state.add_block @name, prog.func.basic_blocks.append "main_body"
  end
end

class CompoundStatementNode < Node
  def pre_walk(prog : Program)
    if self.parent.not_nil!.class == FunctionDeclarationNode
      prog.active = self.parent.not_nil!.as(FunctionDeclarationNode).name
    else
      if self.parent.not_nil!.class == IfStatementNode && prog.active == "if"
        prog.active = "else"
      else
        prog.active = "if"
      end
    end
  end
end

class DeclarationStatementNode < Node
end

class VariableDeclarationNode < Node
  def initialize(@name : String, @type : String)
  end

  def pre_walk(prog : Program)
    prog.builder.position_at_end prog.state.get_block prog.active
    if @type == "int"
      variable_ptr = prog.builder.alloca LLVM::Int32, @name
    end
  end
end

class IfStatementNode < Node
  def pre_walk(prog : Program)
    prog.state.add_block "if", prog.func.basic_blocks.append "if_body"
    prog.state.add_block "else", prog.func.basic_blocks.append "else_body"
  end
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
  def pre_walk(prog : Program)
    prog.state.add_block "return", prog.func.basic_blocks.append "return_block"
    prog.active = "return"
  end
end
