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
      child.pre_walk state
      child.walk state
      child.post_walk state
    end
  end

  def pre_walk(state : ProgramState)
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

    test = @resolved_value
    if @value.as(String) == "puts"
      if test.is_a?(LLVM::Value)
        state.builder.position_at_end state.active_block
        case test.type
        when LLVM::Int32
          state.builder.call state.mod.functions["puts:int"], test, @value.as(String)
        when LLVM::Double
          state.builder.call state.mod.functions["puts:float"], test, @value.as(String)
        when LLVM::Int1
          state.builder.call state.mod.functions["puts:bool"], test, @value.as(String)
        when LLVM::Int8.pointer
          state.builder.call state.mod.functions["puts:str"], test, @value.as(String)
        end
      else
        str_pointer = state.define_or_find_global test.to_s
        state.builder.call state.mod.functions["puts:str"], str_pointer, @value.as(String)
      end
    else
      # FIX this needs to be corrected,
      # this will require adding a new node type to accomodate multiple parameters
      # - ie a ParamArgsNode, with appropriate lexing and code generation

      # Temporary hack, assume one parameter by way of resolved value
      # This needs to be augmented to accept multiple values
      if test.is_a?(LLVM::Value)
        state.builder.call state.mod.functions[@value.as(String)], [test], @value.as(String)
      elsif test.is_a?(Bool)
        if test == true
          state.builder.call state.mod.functions[@value.as(String)], [LLVM.int(LLVM::Int1, 1)], @value.as(String)
        else
          state.builder.call state.mod.functions[@value.as(String)], [LLVM.int(LLVM::Int1, 0)], @value.as(String)
        end
      elsif test.is_a?(Int32)
        state.builder.call state.mod.functions[@value.as(String)], [LLVM.int(LLVM::Int32, test)], @value.as(String)
      elsif test.is_a?(Float64)
        state.builder.call state.mod.functions[@value.as(String)], [LLVM.double(test)], @value.as(String)
      elsif test.is_a?(String)
        str_pointer = state.define_or_find_global test
        state.builder.call state.mod.functions[@value.as(String)], [str_pointer], @value.as(String)
      elsif test.nil?
        state.builder.call state.mod.functions[@value.as(String)], @value.as(String)
      end
    end
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
    lhs = @children[0].resolved_value
    rhs = @children[1].resolved_value

    # FIX many assumptions here that need to be rectified, and actions defined for different types
    if lhs.is_a?(LLVM::Value) && rhs.is_a?(LLVM::Value)
      case lhs.type
      when LLVM::Int32
        case @value
        when "*"
          @resolved_value = state.builder.mul lhs, rhs
        when "/"
          @resolved_value = state.builder.sdiv lhs, rhs
        when "-"
          @resolved_value = state.builder.sub lhs, rhs
        when "+"
          @resolved_value = state.builder.add lhs, rhs
        when "<"
          @resolved_value = state.builder.icmp LLVM::IntPredicate::ULT, lhs, rhs
        when ">"
          @resolved_value = state.builder.icmp LLVM::IntPredicate::UGT, lhs, rhs
        when "!="
          @resolved_value = state.builder.icmp LLVM::IntPredicate::NE, lhs, rhs
        when "=="
          @resolved_value = state.builder.icmp LLVM::IntPredicate::EQ, lhs, rhs
        when "<="
          @resolved_value = state.builder.icmp LLVM::IntPredicate::ULE, lhs, rhs
        when ">="
          @resolved_value = state.builder.icmp LLVM::IntPredicate::UGE, lhs, rhs
        end
      end
    elsif lhs.is_a?(LLVM::Value)
      case lhs.type
      when LLVM::Int32
        case @value
        when "*"
          @resolved_value = state.builder.mul lhs, LLVM.int(LLVM::Int32, rhs.as(Int32))
        when "/"
          @resolved_value = state.builder.sdiv lhs, LLVM.int(LLVM::Int32, rhs.as(Int32))
        when "+"
          @resolved_value = state.builder.add lhs, LLVM.int(LLVM::Int32, rhs.as(Int32))
        when "-"
          @resolved_value = state.builder.sub lhs, LLVM.int(LLVM::Int32, rhs.as(Int32))
        when "<"
          @resolved_value = state.builder.icmp LLVM::IntPredicate::ULT, lhs, LLVM.int(LLVM::Int32, rhs.as(Int32))
        when ">"
          @resolved_value = state.builder.icmp LLVM::IntPredicate::UGT, lhs, LLVM.int(LLVM::Int32, rhs.as(Int32))
        when "!="
          @resolved_value = state.builder.icmp LLVM::IntPredicate::NE, lhs, LLVM.int(LLVM::Int32, rhs.as(Int32))
        when "=="
          @resolved_value = state.builder.icmp LLVM::IntPredicate::EQ, lhs, LLVM.int(LLVM::Int32, rhs.as(Int32))
        when "<="
          @resolved_value = state.builder.icmp LLVM::IntPredicate::ULE, lhs, LLVM.int(LLVM::Int32, rhs.as(Int32))
        when ">="
          @resolved_value = state.builder.icmp LLVM::IntPredicate::UGE, lhs, LLVM.int(LLVM::Int32, rhs.as(Int32))
        end
      end
    elsif rhs.is_a?(LLVM::Value)
      if lhs.is_a?(Int32)
        case @value
        when "*"
          @resolved_value = state.builder.mul LLVM.int(LLVM::Int32, lhs.as(Int32)), rhs
        when "/"
          @resolved_value = state.builder.sdiv LLVM.int(LLVM::Int32, lhs.as(Int32)), rhs
        when "+"
          @resolved_value = state.builder.add LLVM.int(LLVM::Int32, lhs.as(Int32)), rhs
        when "-"
          @resolved_value = state.builder.sub LLVM.int(LLVM::Int32, lhs.as(Int32)), rhs
        when "<"
          @resolved_value = state.builder.icmp LLVM::IntPredicate::ULT, LLVM.int(LLVM::Int32, lhs.as(Int32)), rhs
        when ">"
          @resolved_value = state.builder.icmp LLVM::IntPredicate::UGT, LLVM.int(LLVM::Int32, lhs.as(Int32)), rhs
        when "!="
          @resolved_value = state.builder.icmp LLVM::IntPredicate::NE, LLVM.int(LLVM::Int32, lhs.as(Int32)), rhs
        when "=="
          @resolved_value = state.builder.icmp LLVM::IntPredicate::EQ, LLVM.int(LLVM::Int32, lhs.as(Int32)), rhs
        when "<="
          @resolved_value = state.builder.icmp LLVM::IntPredicate::ULE, LLVM.int(LLVM::Int32, lhs.as(Int32)), rhs
        when ">="
          @resolved_value = state.builder.icmp LLVM::IntPredicate::UGE, LLVM.int(LLVM::Int32, lhs.as(Int32)), rhs
        end
      end
    elsif lhs.is_a?(Int32) && rhs.is_a?(Int32) # Integer and integer
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

class IfExpressionNode < Node
  property! exit_block, if_block, else_block, entry_block
  @entry_block : LLVM::BasicBlock?
  @exit_block : LLVM::BasicBlock?
  @if_block : LLVM::BasicBlock?
  @else_block : LLVM::BasicBlock?

  def initialize(@line : Int32, @position : Int32)
    @value = nil
    @children = [] of Node
  end

  def pre_walk(state : ProgramState)
    block_name = "eblock#{state.blocks.size + 1}"
    exit_block = state.mod.functions["main"].basic_blocks.append block_name
    state.add_block block_name, exit_block
    @entry_block = state.active_block
    @exit_block = exit_block
  end

  def resolve_value(state : ProgramState)
    state.active_block = @exit_block
    @if_block = @children[1].as(BasicBlockNode).block
    if @children[2]?
      @else_block = @children[2].as(BasicBlockNode).block
    end

    if @children[0].resolved_value == true
      @resolved_value = @children[1].resolved_value
    else
      if @children[2]?
        @resolved_value = @children[2].resolved_value
      end
    end

    comp_val = @children[0].resolved_value
    if comp_val == true
      comp_val = LLVM.int(LLVM::Int1, 1)
    else
      comp_val = LLVM.int(LLVM::Int1, 0)
    end

    if @children[2]?
      state.close_statements.push ConditionalStatement.new entry_block, comp_val, if_block, else_block
    else
      state.close_statements.push ConditionalStatement.new entry_block, comp_val, if_block, exit_block
    end
  end
end

class BasicBlockNode < Node
  property! block
  @block : LLVM::BasicBlock?

  def initialize(@line : Int32, @position : Int32)
    @value = nil
    @children = [] of Node
  end

  def pre_walk(state : ProgramState)
    block_name = "block#{state.blocks.size + 1}"
    self_block = state.mod.functions["main"].basic_blocks.append block_name
    state.add_block block_name, self_block
    state.active_block = self_block
    @block = self_block
  end

  def resolve_value(state : ProgramState)
    @resolved_value = @children[-1].resolved_value
    scope = block
    @children.each do |child|
      if child.class == IfExpressionNode
        scope = child.as(IfExpressionNode).exit_block
      end
    end
    state.close_statements.push JumpStatement.new scope, parent.as(IfExpressionNode).exit_block
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

class VariableDeclarationNode < Node
  def initialize(@value : String, @line : Int32, @position : Int32)
    @children = [] of Node
  end

  def resolve_value(state : ProgramState)
    @resolved_value = @children[0].resolved_value
    state.add_variable state.active_function, @value.as(String), @resolved_value
  end
end

class DeclarationReferenceNode < Node
  def initialize(@value : String, @line : Int32, @position : Int32)
    @children = [] of Node
  end

  def resolve_value(state : ProgramState)
    @resolved_value = state.reference_variable state.active_function, @value.as(String), @line, @position
  end
end

class ReturnNode < Node
  def initialize(@line : Int32, @position : Int32)
    @value = nil
    @children = [] of Node
  end

  def resolve_value(state : ProgramState)
    @resolved_value = @children[0].resolved_value
    test = @resolved_value
    if test.is_a? Int32
      state.builder.position_at_end state.active_block
      if test.is_a?(LLVM::Value)
        state.builder.ret test
      elsif test.is_a?(Bool)
        if test == true
          state.builder.ret LLVM.int(LLVM::Int1, 1)
        else
          state.builder.ret LLVM.int(LLVM::Int1, 0)
        end
      elsif test.is_a?(String)
        str_pointer = state.define_or_find_global test
        state.builder.ret str_pointer
      elsif test.is_a?(Int32)
        state.builder.ret LLVM.int(LLVM::Int32, test)
      elsif test.is_a?(Float64)
        state.builder.ret LLVM.double(test)
      elsif test.nil?
        state.builder.ret
      end
    end
  end
end
