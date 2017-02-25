class Node
  getter value
  property children, resolved_value
  property! parent

  @value : ValueType
  @resolved_value : ValueType | LLVM::Value
  @parent : Node?

  def initialize(@line : Int32, @position : Int32)
    @children = [] of Node
    @value = nil
    @resolved_value = nil
  end

  def add_child(node : Node) : Nil
    @children.push node
    node.parent = self
  end

  def delete_child(node : Node) : Nil
    @children.delete node
  end

  def promote(node : Node) : Nil
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

  def get_first_parens_node : Node
    active_parent = self.parent
    while true
      # if active parent is an expression, we are done
      if active_parent.class == ExpressionNode && active_parent.as(ExpressionNode).parens == true
        return active_parent
      else
        # Otherwise we need to keep looking upwards
        active_parent = active_parent.parent
      end
      if active_parent.class == RootNode
        # TODO This is currently working as expected but should be tested more
        return self.parent
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

  def walk(state : ProgramState) : Nil
    # Print AST in walk order with depth
    puts "#{"\t" * depth}#{self.class} #{self.value}" if state.printAST
    @children.each do |child|
      child.pre_walk state
      child.walk state
      child.post_walk state
    end
  end

  def pre_walk(state : ProgramState) : Nil
  end

  def post_walk(state : ProgramState) : Nil
    resolve_value state
    # Print AST resolutions
    puts "#{"\t" * depth}#{self.class} resolved #{@resolved_value}" if state.printResolutions
  end

  def resolve_value(state : ProgramState) : Nil
  end

  def crystal_to_llvm(state : ProgramState, value : ValueType) : LLVM::Value
    if value.is_a?(Bool)
      if value == true
        return state.int1.const_int(1)
      else
        return state.int1.const_int(0)
      end
    elsif value.is_a?(Int32)
      return state.int32.const_int(value)
    elsif value.is_a?(Float64)
      return state.double.const_double(value)
    elsif value.is_a?(String)
      return state.define_or_find_global value
    elsif value.is_a?(LLVM::Value)
      return value
    else
      raise "Unknown value type in crystal_to_llvm function"
    end
  end
end
