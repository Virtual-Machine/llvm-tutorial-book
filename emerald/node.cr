class Node
  getter value
  property children, resolved_value
  property! parent

  @value : ValueType
  @resolved_value : ValueType
  @parent : Node?

  def initialize(@line : Int32, @position : Int32)
    @children = [] of Node
    @value = nil
    @resolved_value = nil
  end

  def add_child(node : Node)
    @children.push node
    node.parent = self
  end

  def delete_child(node : Node)
    @children.delete node
  end

  def promote(node : Node)
    insertion_point = get_binary_insertion_point node

    root_node = insertion_point.parent
    root_node.delete_child insertion_point
    root_node.add_child node
    node.add_child insertion_point
  end

  def get_binary_insertion_point(node : Node) : Node
    insert_point = self
    while true
      if insert_point.parent.class == BinaryOperatorNode && node.precedence <= insert_point.parent.as(BinaryOperatorNode).precedence
        insert_point = insert_point.parent
      else
        break
      end
    end
    insert_point
  end

  def get_first_expression_node : Node
    active_parent = self.parent
    while true
      # if active parent is an expression, we are done
      if active_parent.class == ExpressionNode
        return active_parent
      else
        # Otherwise we need to keep looking upwards
        active_parent = active_parent.parent
      end
    end
  end

  def depth : Int32
    count = 0
    active_node = self
    while true
      if active_node.class == RootNode
        return count
      else
        active_node = active_node.parent
        count += 1
      end
    end
  end

  def walk(state : ProgramState)
    # Print AST in walk order with depth
    puts "#{"\t" * depth}#{self.class} #{self.value}" if state.printAST
    @children.each do |child|
      child.walk state
      child.post_walk state
    end
  end

  def post_walk(state : ProgramState)
    resolve_value state
    # Print AST resolutions
    puts "#{"\t" * depth}#{self.class} resolved #{@resolved_value}" if state.printResolutions
  end

  def resolve_value(state : ProgramState)
  end
end

class RootNode < Node
  def initialize
    super 1, 1
    @value = nil
    @parent = nil
  end

  def resolve_value(state : ProgramState)
    @resolved_value = @children[-1].resolved_value
  end
end

class CallExpressionNode < Node
  def initialize(@value : ValueType, @line : Int32, @position : Int32)
    @children = [] of Node
  end

  def resolve_value(state : ProgramState)
    @resolved_value = @children[0].resolved_value
    state.add_instruction CallInstruction.new state.functions[@value], [LLVM.string(@resolved_value.to_s)], "call_expression", @line, @position
  end
end

class VariableDeclarationNode < Node
  def initialize(@value : String, @line : Int32, @position : Int32)
    @children = [] of Node
  end

  def resolve_value(state : ProgramState)
    @resolved_value = @children[0].resolved_value
    state.add_variable @value.as(String), @resolved_value
  end
end

class BinaryOperatorNode < Node
  def initialize(@value : String, @line : Int32, @position : Int32)
    @children = [] of Node
  end

  def precedence : Int32
    case value
    when "+"
      5
    when "-"
      5
    when "*"
      10
    when "/"
      10
    else
      0
    end
  end

  def resolve_value(state : ProgramState)
    # Currently only binary integer expressions are functional
    lhs = @children[0].resolved_value
    rhs = @children[1].resolved_value
    if lhs.is_a?(Int32) && rhs.is_a?(Int32) # Integer and integer
      case @value
      when "+"
        @resolved_value = lhs + rhs
      when "-"
        @resolved_value = lhs - rhs
      when "*"
        @resolved_value = lhs * rhs
      when "/"
        @resolved_value = lhs / rhs
      when "=="
        @resolved_value = lhs == rhs
      when "!="
        @resolved_value = lhs != rhs
      when "<"
        @resolved_value = lhs < rhs
      when ">"
        @resolved_value = lhs > rhs
      when "<="
        @resolved_value = lhs <= rhs
      when ">="
        @resolved_value = lhs >= rhs
      else
        raise EmeraldValueResolutionException.new "Undefined operation #{@value} on integer values #{lhs} #{rhs}", @line, @position
      end
    elsif lhs.is_a?(Float64) && rhs.is_a?(Float64) # Float and float
      case @value
      when "+"
        @resolved_value = lhs + rhs
      when "-"
        @resolved_value = lhs - rhs
      when "*"
        @resolved_value = lhs * rhs
      when "/"
        @resolved_value = lhs / rhs
      when "=="
        @resolved_value = lhs == rhs
      when "!="
        @resolved_value = lhs != rhs
      when "<"
        @resolved_value = lhs < rhs
      when ">"
        @resolved_value = lhs > rhs
      when "<="
        @resolved_value = lhs <= rhs
      when ">="
        @resolved_value = lhs >= rhs
      else
        raise EmeraldValueResolutionException.new "Undefined operation #{@value} on float values #{lhs} #{rhs}", @line, @position
      end
    elsif lhs.is_a?(Float64) && rhs.is_a?(Int32) # Float and integer
      case @value
      when "+"
        @resolved_value = lhs + rhs
      when "-"
        @resolved_value = lhs - rhs
      when "*"
        @resolved_value = lhs * rhs
      when "/"
        @resolved_value = lhs / rhs
      when "=="
        @resolved_value = lhs == rhs
      when "!="
        @resolved_value = lhs != rhs
      when "<"
        @resolved_value = lhs < rhs
      when ">"
        @resolved_value = lhs > rhs
      when "<="
        @resolved_value = lhs <= rhs
      when ">="
        @resolved_value = lhs >= rhs
      else
        raise EmeraldValueResolutionException.new "Undefined operation #{@value} on float64 #{lhs} and int32 #{rhs}", @line, @position
      end
    elsif lhs.is_a?(Int32) && rhs.is_a?(Float64) # Integer and float
      case @value
      when "+"
        @resolved_value = lhs + rhs
      when "-"
        @resolved_value = lhs - rhs
      when "*"
        @resolved_value = lhs * rhs
      when "/"
        @resolved_value = lhs / rhs
      when "=="
        @resolved_value = lhs == rhs
      when "!="
        @resolved_value = lhs != rhs
      when "<"
        @resolved_value = lhs < rhs
      when ">"
        @resolved_value = lhs > rhs
      when "<="
        @resolved_value = lhs <= rhs
      when ">="
        @resolved_value = lhs >= rhs
      else
        raise EmeraldValueResolutionException.new "Undefined operation #{@value} on int32 #{lhs} and float64 #{rhs}", @line, @position
      end
    elsif lhs.is_a?(String) && rhs.is_a?(String)
      case @value
      when "+"
        @resolved_value = lhs + rhs
      when "=="
        @resolved_value = lhs == rhs
      when "!="
        @resolved_value = lhs != rhs
      else
        raise EmeraldValueResolutionException.new "Undefined operation #{@value} on string values \"#{lhs}\" \"#{rhs}\"", @line, @position
      end
    elsif lhs.is_a?(String) && rhs.is_a?(Int32)
      case @value
      when "*"
        @resolved_value = lhs * rhs
      else
        raise EmeraldValueResolutionException.new "Undefined operation #{@value} on string \"#{lhs}\" and int32 #{rhs}", @line, @position
      end
    elsif lhs.is_a?(Bool) && rhs.is_a?(Bool)
      case @value
      when "=="
        @resolved_value = lhs == rhs
      when "!="
        @resolved_value = lhs != rhs
      else
        raise EmeraldValueResolutionException.new "Undefined operation #{@value} on boolean values #{lhs} #{rhs}", @line, @position
      end
    else
      raise EmeraldValueResolutionException.new "Undefined operation #{@value} based on types LHS -> #{lhs} RHS -> #{rhs}", @line, @position
    end
  end
end

class IntegerLiteralNode < Node
  def initialize(@value : Int32, @line : Int32, @position : Int32)
    @children = [] of Node
  end

  def resolve_value(state : ProgramState)
    @resolved_value = value
  end
end

class StringLiteralNode < Node
  def initialize(@value : String, @line : Int32, @position : Int32)
    @children = [] of Node
  end

  def resolve_value(state : ProgramState)
    @resolved_value = value
  end
end

class FloatLiteralNode < Node
  def initialize(@value : Float64, @line : Int32, @position : Int32)
    @children = [] of Node
  end

  def resolve_value(state : ProgramState)
    @resolved_value = value
  end
end

class BooleanLiteralNode < Node
  def initialize(@value : Bool, @line : Int32, @position : Int32)
    @children = [] of Node
  end

  def resolve_value(state : ProgramState)
    @resolved_value = value
  end
end

class DeclarationReferenceNode < Node
  def initialize(@value : String, @line : Int32, @position : Int32)
    @children = [] of Node
  end

  def resolve_value(state : ProgramState)
    @resolved_value = state.reference_variable @value.as(String), @line, @position
  end
end

class IfExpressionNode < Node
  def initialize(@line : Int32, @position : Int32)
    @value = nil
    @children = [] of Node
  end

  def resolve_value(state : ProgramState)
    if @children[0].resolved_value
      @resolved_value = @children[1].resolved_value
    else
      if @children.size == 2
        @resolved_value = @children[2].resolved_value
      end
    end
  end
end

class BasicBlockNode < Node
  def initialize(@line : Int32, @position : Int32)
    @value = nil
    @children = [] of Node
  end

  def resolve_value(state : ProgramState)
    @resolved_value = @children[-1].resolved_value
  end
end

class ExpressionNode < Node
  def initialize(@line : Int32, @position : Int32)
    @value = nil
    @children = [] of Node
  end

  def resolve_value(state : ProgramState)
    @resolved_value = @children[0].resolved_value
  end
end

class ReturnNode < Node
  def initialize(@line : Int32, @position : Int32)
    @value = nil
    @children = [] of Node
  end

  def resolve_value(state : ProgramState)
    @resolved_value = @children[0].resolved_value
    if @resolved_value.is_a? Int32
      state.add_instruction ReturnInstruction.new @resolved_value, "Int32", "return", @line, @position
    end
  end
end
