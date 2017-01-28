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

  def crystal_to_llvm(state : ProgramState, value : ValueType) : LLVM::Value
    if value.is_a?(Bool)
      if value == true
        return LLVM.int(LLVM::Int1, 1)
      else
        return LLVM.int(LLVM::Int1, 0)
      end
    elsif value.is_a?(Int32)
      return LLVM.int(LLVM::Int32, value)
    elsif value.is_a?(Float64)
      return LLVM.double(value)
    elsif value.is_a?(String)
      return state.define_or_find_global value
    elsif value.is_a?(LLVM::Value)
      return value
    else
      raise "Unknown value type in crystal_to_llvm function"
    end
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
    state.builder.position_at_end state.active_block
    if @value.as(String) == "puts"
      @resolved_value = @children[0].resolved_value
      test = @resolved_value
      if test.is_a?(LLVM::Value)
        case test.type
        when LLVM::Int64
          state.builder.call state.mod.functions["puts:int64"], test, @value.as(String)
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
      num_params = @children.size
      if num_params == 0
        @resolved_value = state.builder.call state.mod.functions[@value.as(String)], @value.as(String)
      else
        params = [] of LLVM::Value
        @children.each do |child|
          params.push crystal_to_llvm state, child.resolved_value
        end
        @resolved_value = state.builder.call state.mod.functions[@value.as(String)], params, @value.as(String)
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
        if rhs.type == LLVM::Int32
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
        elsif rhs.type == LLVM::Double
          lhs_val = state.builder.si2fp lhs, LLVM::Double
          case @value
          when "*"
            @resolved_value = state.builder.fmul lhs_val, rhs
          when "/"
            @resolved_value = state.builder.fdiv lhs_val, rhs
          when "-"
            @resolved_value = state.builder.fsub lhs_val, rhs
          when "+"
            @resolved_value = state.builder.fadd lhs_val, rhs
          when "<"
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::ULT, lhs_val, rhs
          when ">"
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UGT, lhs_val, rhs
          when "!="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UNE, lhs_val, rhs
          when "=="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UEQ, lhs_val, rhs
          when "<="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::ULE, lhs_val, rhs
          when ">="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UGE, lhs_val, rhs
          end
        else
          raise EmeraldValueResolutionException.new "Undefined operation #{@value} for rhs type (BOTH = LLVM::Value) #{lhs} #{rhs}", @line, @position
        end
      when LLVM::Int1
        if rhs.type == LLVM::Int1
          case @value
          when "!="
            @resolved_value = state.builder.icmp LLVM::IntPredicate::NE, lhs, rhs
          when "=="
            @resolved_value = state.builder.icmp LLVM::IntPredicate::EQ, lhs, rhs
          end
        else
          raise EmeraldValueResolutionException.new "Undefined operation #{@value} for rhs type (BOTH = LLVM::Value) #{lhs} #{rhs}", @line, @position
        end
      when LLVM::Int8.pointer
        if rhs.type == LLVM::Int8.pointer
          case @value
          when "!="
            @resolved_value = state.builder.icmp LLVM::IntPredicate::NE, lhs, rhs
          when "=="
            @resolved_value = state.builder.icmp LLVM::IntPredicate::EQ, lhs, rhs
            # INCOMPLETE no string concatenation implementation in LLVM yet
          end
        elsif rhs.type == LLVM::Int32
          # INCOMPLETE no string repetition implementation in LLVM yet
        else
          raise EmeraldValueResolutionException.new "Undefined operation #{@value} for rhs type (BOTH = LLVM::Value) #{lhs} #{rhs}", @line, @position
        end
      when LLVM::Double
        if rhs.type == LLVM::Double
          case @value
          when "*"
            @resolved_value = state.builder.fmul lhs, rhs
          when "/"
            @resolved_value = state.builder.fdiv lhs, rhs
          when "-"
            @resolved_value = state.builder.fsub lhs, rhs
          when "+"
            @resolved_value = state.builder.fadd lhs, rhs
          when "<"
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::ULT, lhs, rhs
          when ">"
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UGT, lhs, rhs
          when "!="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UNE, lhs, rhs
          when "=="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UEQ, lhs, rhs
          when "<="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::ULE, lhs, rhs
          when ">="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UGE, lhs, rhs
          end
        elsif rhs.type == LLVM::Int32
          rhs_val = state.builder.si2fp rhs, LLVM::Double
          case @value
          when "*"
            @resolved_value = state.builder.fmul lhs, rhs_val
          when "/"
            @resolved_value = state.builder.fdiv lhs, rhs_val
          when "-"
            @resolved_value = state.builder.fsub lhs, rhs_val
          when "+"
            @resolved_value = state.builder.fadd lhs, rhs_val
          when "<"
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::ULT, lhs, rhs_val
          when ">"
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UGT, lhs, rhs_val
          when "!="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UNE, lhs, rhs_val
          when "=="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UEQ, lhs, rhs_val
          when "<="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::ULE, lhs, rhs_val
          when ">="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UGE, lhs, rhs_val
          end
        else
          raise EmeraldValueResolutionException.new "Undefined operation #{@value} for rhs type (BOTH = LLVM::Value) #{lhs} #{rhs}", @line, @position
        end
      else
        raise EmeraldValueResolutionException.new "Undefined operation #{@value} for lhs type (BOTH = LLVM::Value) #{lhs} #{rhs}", @line, @position
      end
    elsif lhs.is_a?(LLVM::Value)
      case lhs.type
      when LLVM::Int32
        if rhs.is_a?(Int32)
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
        elsif rhs.is_a?(Float64)
          lhs_val = lhs_val = state.builder.si2fp lhs, LLVM::Double
          rhs_val = LLVM.double(rhs)
          case @value
          when "*"
            @resolved_value = state.builder.fmul lhs_val, rhs_val
          when "/"
            @resolved_value = state.builder.fdiv lhs_val, rhs_val
          when "+"
            @resolved_value = state.builder.fadd lhs_val, rhs_val
          when "-"
            @resolved_value = state.builder.fsub lhs_val, rhs_val
          when "<"
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::ULT, lhs_val, rhs_val
          when ">"
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UGT, lhs_val, rhs_val
          when "!="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UNE, lhs_val, rhs_val
          when "=="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UEQ, lhs_val, rhs_val
          when "<="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::ULE, lhs_val, rhs_val
          when ">="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UGE, lhs_val, rhs_val
          end
        else
          raise EmeraldValueResolutionException.new "Undefined operation #{@value} for rhs type (LHS = LLVM::Value) #{lhs} #{rhs}", @line, @position
        end
      when LLVM::Int1
        if rhs.is_a?(Bool)
          if rhs == true
            rhs_val = LLVM.int(LLVM::Int1, 1)
          else
            rhs_val = LLVM.int(LLVM::Int1, 0)
          end
          case @value
          when "!="
            @resolved_value = state.builder.icmp LLVM::IntPredicate::NE, lhs, rhs_val
          when "=="
            @resolved_value = state.builder.icmp LLVM::IntPredicate::EQ, lhs, rhs_val
          end
        else
          raise EmeraldValueResolutionException.new "Undefined operation #{@value} for rhs type (LHS = LLVM::Value) #{lhs} #{rhs}", @line, @position
        end
      when LLVM::Int8.pointer
        if rhs.is_a?(String)
          rhs_val = state.define_or_find_global rhs
          case @value
          when "!="
            @resolved_value = state.builder.icmp LLVM::IntPredicate::NE, lhs, rhs_val
          when "=="
            @resolved_value = state.builder.icmp LLVM::IntPredicate::EQ, lhs, rhs_val
            # INCOMPLETE no string concatenation implementation in LLVM yet
          end
        elsif rhs.is_a?(Int32)
          # INCOMPLETE no string repetition implementation in LLVM yet
        else
          raise EmeraldValueResolutionException.new "Undefined operation #{@value} for rhs type (LHS = LLVM::Value) #{lhs} #{rhs}", @line, @position
        end
      when LLVM::Double
        if rhs.is_a?(Float64)
          rhs_val = LLVM.double(rhs)
          case @value
          when "*"
            @resolved_value = state.builder.fmul lhs, rhs_val
          when "/"
            @resolved_value = state.builder.fdiv lhs, rhs_val
          when "-"
            @resolved_value = state.builder.fsub lhs, rhs_val
          when "+"
            @resolved_value = state.builder.fadd lhs, rhs_val
          when "<"
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::ULT, lhs, rhs_val
          when ">"
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UGT, lhs, rhs_val
          when "!="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UNE, lhs, rhs_val
          when "=="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UEQ, lhs, rhs_val
          when "<="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::ULE, lhs, rhs_val
          when ">="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UGE, lhs, rhs_val
          end
        elsif rhs.is_a?(Int32)
          rhs_val = LLVM.double(rhs.to_f)
          case @value
          when "*"
            @resolved_value = state.builder.fmul lhs, rhs_val
          when "/"
            @resolved_value = state.builder.fdiv lhs, rhs_val
          when "-"
            @resolved_value = state.builder.fsub lhs, rhs_val
          when "+"
            @resolved_value = state.builder.fadd lhs, rhs_val
          when "<"
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::ULT, lhs, rhs_val
          when ">"
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UGT, lhs, rhs_val
          when "!="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UNE, lhs, rhs_val
          when "=="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UEQ, lhs, rhs_val
          when "<="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::ULE, lhs, rhs_val
          when ">="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UGE, lhs, rhs_val
          end
        else
          raise EmeraldValueResolutionException.new "Undefined operation #{@value} for rhs type (LHS = LLVM::Value) #{lhs} #{rhs}", @line, @position
        end
      else
        raise EmeraldValueResolutionException.new "Undefined operation #{@value} for lhs type (LHS = LLVM::Value) #{lhs} #{rhs}", @line, @position
      end
    elsif rhs.is_a?(LLVM::Value)
      if lhs.is_a?(Int32)
        if rhs.type == LLVM::Int32
          lhs_val = LLVM.int(LLVM::Int32, lhs.as(Int32))
          case @value
          when "*"
            @resolved_value = state.builder.mul lhs_val, rhs
          when "/"
            @resolved_value = state.builder.sdiv lhs_val, rhs
          when "+"
            @resolved_value = state.builder.add lhs_val, rhs
          when "-"
            @resolved_value = state.builder.sub lhs_val, rhs
          when "<"
            @resolved_value = state.builder.icmp LLVM::IntPredicate::ULT, lhs_val, rhs
          when ">"
            @resolved_value = state.builder.icmp LLVM::IntPredicate::UGT, lhs_val, rhs
          when "!="
            @resolved_value = state.builder.icmp LLVM::IntPredicate::NE, lhs_val, rhs
          when "=="
            @resolved_value = state.builder.icmp LLVM::IntPredicate::EQ, lhs_val, rhs
          when "<="
            @resolved_value = state.builder.icmp LLVM::IntPredicate::ULE, lhs_val, rhs
          when ">="
            @resolved_value = state.builder.icmp LLVM::IntPredicate::UGE, lhs_val, rhs
          end
        elsif rhs.type == LLVM::Double
          lhs_val = LLVM.double(lhs.to_f)
          case @value
          when "*"
            @resolved_value = state.builder.fmul lhs_val, rhs
          when "/"
            @resolved_value = state.builder.fdiv lhs_val, rhs
          when "+"
            @resolved_value = state.builder.fadd lhs_val, rhs
          when "-"
            @resolved_value = state.builder.fsub lhs_val, rhs
          when "<"
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::ULT, lhs_val, rhs
          when ">"
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UGT, lhs_val, rhs
          when "!="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UNE, lhs_val, rhs
          when "=="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UEQ, lhs_val, rhs
          when "<="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::ULE, lhs_val, rhs
          when ">="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UGE, lhs_val, rhs
          end
        else
          raise EmeraldValueResolutionException.new "Undefined operation #{@value} for rhs type (RHS = LLVM::Value) #{lhs} #{rhs}", @line, @position
        end
      elsif lhs.is_a?(Bool)
        if rhs.type == LLVM::Int1
          if lhs == true
            lhs_val = LLVM.int(LLVM::Int1, 1)
          else
            lhs_val = LLVM.int(LLVM::Int1, 0)
          end
          case @value
          when "!="
            @resolved_value = state.builder.icmp LLVM::IntPredicate::NE, lhs_val, rhs
          when "=="
            @resolved_value = state.builder.icmp LLVM::IntPredicate::EQ, lhs_val, rhs
          end
        else
          raise EmeraldValueResolutionException.new "Undefined operation #{@value} for rhs type (RHS = LLVM::Value) #{lhs} #{rhs}", @line, @position
        end
      elsif lhs.is_a?(Float64)
        if rhs.type == LLVM::Double
          lhs_val = LLVM.double(lhs)
          case @value
          when "*"
            @resolved_value = state.builder.fmul lhs_val, rhs
          when "/"
            @resolved_value = state.builder.fdiv lhs_val, rhs
          when "-"
            @resolved_value = state.builder.fsub lhs_val, rhs
          when "+"
            @resolved_value = state.builder.fadd lhs_val, rhs
          when "<"
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::ULT, lhs_val, rhs
          when ">"
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UGT, lhs_val, rhs
          when "!="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UNE, lhs_val, rhs
          when "=="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UEQ, lhs_val, rhs
          when "<="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::ULE, lhs_val, rhs
          when ">="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UGE, lhs_val, rhs
          end
        elsif rhs.type == LLVM::Int32
          lhs_val = LLVM.double(lhs)
          rhs_val = state.builder.si2fp rhs, LLVM::Double
          case @value
          when "*"
            @resolved_value = state.builder.fmul lhs_val, rhs_val
          when "/"
            @resolved_value = state.builder.fdiv lhs_val, rhs_val
          when "-"
            @resolved_value = state.builder.fsub lhs_val, rhs_val
          when "+"
            @resolved_value = state.builder.fadd lhs_val, rhs_val
          when "<"
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::ULT, lhs_val, rhs_val
          when ">"
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UGT, lhs_val, rhs_val
          when "!="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UNE, lhs_val, rhs_val
          when "=="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UEQ, lhs_val, rhs_val
          when "<="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::ULE, lhs_val, rhs_val
          when ">="
            @resolved_value = state.builder.fcmp LLVM::RealPredicate::UGE, lhs_val, rhs_val
          end
        else
          raise EmeraldValueResolutionException.new "Undefined operation #{@value} for rhs type (RHS = LLVM::Value) #{lhs} #{rhs}", @line, @position
        end
      elsif lhs.is_a?(String)
        if rhs.type == LLVM::Int8.pointer
          lhs_val = state.define_or_find_global lhs
          case @value
          when "!="
            @resolved_value = state.builder.icmp LLVM::IntPredicate::NE, lhs_val, rhs
          when "=="
            @resolved_value = state.builder.icmp LLVM::IntPredicate::EQ, lhs_val, rhs
            # INCOMPLETE no string concatenation implementation in LLVM yet
          end
        elsif rhs.is_a?(Int32)
          # INCOMPLETE no string repetition implementation in LLVM yet
        else
          raise EmeraldValueResolutionException.new "Undefined operation #{@value} for rhs type (RHS = LLVM::Value) #{lhs} #{rhs}", @line, @position
        end
      else
        raise EmeraldValueResolutionException.new "Undefined operation #{@value} for lhs type (RHS = LLVM::Value) #{lhs} #{rhs}", @line, @position
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
    self_block = state.active_function.basic_blocks.append block_name
    state.add_block block_name, self_block
    state.active_block = self_block
    @block = self_block
  end

  def resolve_value(state : ProgramState)
    @resolved_value = @children[-1].resolved_value
    if parent.is_a?(IfExpressionNode)
      scope = block
      @children.each do |child|
        if child.class == IfExpressionNode
          scope = child.as(IfExpressionNode).exit_block
        end
      end
      state.close_statements.push JumpStatement.new scope, parent.as(IfExpressionNode).exit_block  
    end
  end
end

class ExpressionNode < Node
  getter parens

  def initialize(@parens : Bool, @line : Int32, @position : Int32)
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
    if @resolved_value.is_a?(String)
      state.define_or_find_global @resolved_value.as(String)
    end
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

class FunctionDeclarationNode < Node
  def initialize(@name : String, @params : Hash(String, Symbol), @return_type : Symbol, @line : Int32, @position : Int32)
    @value = nil
    @children = [] of Node
  end

  def pre_walk(state : ProgramState)
    state.saved_block = state.active_block
    params = [] of LLVM::Type
    param_names = [] of String
    @params.each do |name, type_val|
      params.push symbol_to_llvm type_val
      param_names.push name
    end
    return_sig = symbol_to_llvm @return_type
    func = state.mod.functions.add @name, params, return_sig
    state.active_function = func
    array = func.params.to_a
    array.each_with_index do |param, i|
      state.add_variable func, param_names[i], param 
    end
  end

  def resolve_value(state : ProgramState)
    state.active_function = state.mod.functions["main"]
    state.active_block = state.saved_block
  end

  def symbol_to_llvm(symbol : Symbol) : LLVM::Type
    case symbol
    when :Int32
      return LLVM::Int32
    when :Int64
      return LLVM::Int64
    when :Float64
      return LLVM::Double
    when :Bool
      return LLVM::Int1
    when :String
      return LLVM::Int8.pointer
    else
      raise "Undefined case in symbol_to_llvm"
    end
  end
end

class TypeCastNode < Node
  def initialize(@resolved_value : LLVM::Type, @line : Int32, @position : Int32)
    @value = nil
    @children = [] of Node
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
