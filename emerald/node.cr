class Node
  getter value
  property parent, children, resolved_value

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

  def promote(node : Node)
    insertion_point = get_binary_insertion_point node

    held_children = insertion_point.not_nil!.children
    insertion_point.not_nil!.children = [] of Node
    insertion_point.not_nil!.add_child node
    held_children.each do |child|
      node.add_child child
    end
  end

  def get_binary_insertion_point(node : Node) : Node
    active_parent = self.parent
    while true
      # Check if insertion point is a binary operator
      if active_parent.class == BinaryOperatorNode && node.precedence < active_parent.as(BinaryOperatorNode).precedence
        # If active_parent.parent is a node
        if !active_parent.not_nil!.parent.nil?
          active_parent = active_parent.not_nil!.parent
        else
          break
        end
      else
        break
      end
    end
    # We know active parent is not nil because there should
    # always be the root node at the top to kill the ast chain
    active_parent.not_nil!
  end

  def get_first_expression_node : Node
    active_parent = self.parent
    while true
      # if active parent is an expression, we are done
      if active_parent.class == ExpressionNode
        return active_parent.not_nil!
      else
        # Otherwise we need to keep looking upwards
        active_parent = active_parent.not_nil!.parent
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
        active_node = active_node.not_nil!.parent
        count += 1
      end
    end
  end

  def walk(state : State) : State
    # Print AST in walk order with depth
    # puts "#{"\t" * depth}#{self.class} #{self.value}"
    @children.each do |child|
      child.pre_walk
      state = child.walk state
      state = child.post_walk state
    end
    state
  end

  def pre_walk : Nil
    # Ready for initialization calls
  end

  def post_walk(state : State) : State
    state = resolve_value state
    # Print AST resolutions
    # puts "#{self.class} resolved #{@resolved_value}"
    state
  end

  def resolve_value(state : State) : State
    state
  end
end

class RootNode < Node
  def initialize
    super 1, 1
    @value = nil
    @parent = nil
  end

  def resolve_value(state : State) : State
    @resolved_value = @children[-1].resolved_value
    state
  end
end

class CallExpressionNode < Node
  def initialize(@value : ValueType, @line : Int32, @position : Int32)
    @children = [] of Node
  end

  def resolve_value(state : State) : State
    @resolved_value = @children[0].resolved_value
    state
  end
end

class VariableDeclarationNode < Node
  def initialize(@value : String, @line : Int32, @position : Int32)
    @children = [] of Node
  end

  def resolve_value(state : State) : State
    @resolved_value = @children[0].resolved_value
    state[@value.as(String)] = @resolved_value
    state
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

  def resolve_value(state : State) : State
    lhs = @children[0].resolved_value.as(Int32)
    rhs = @children[1].resolved_value.as(Int32)
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
    end
    state
  end
end

class IntegerLiteralNode < Node
  def initialize(@value : Int32, @line : Int32, @position : Int32)
    @children = [] of Node
  end

  def resolve_value(state : State) : State
    @resolved_value = value
    state
  end
end

class DeclarationReferenceNode < Node
  def initialize(@value : String, @line : Int32, @position : Int32)
    @children = [] of Node
  end

  def resolve_value(state : State) : State
    @resolved_value = state[@value]
    state
  end
end

class ExpressionNode < Node
  def initialize(@line : Int32, @position : Int32)
    @value = nil
    @children = [] of Node
  end

  def resolve_value(state : State) : State
    @resolved_value = @children[0].resolved_value
    state
  end
end
