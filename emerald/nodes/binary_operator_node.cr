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

  # resolve value valid possibilities
  # Note we may need to add in LLVM::Int64 due to its presence in the standard lib.
  # This could also be solved by using wrappers around functions to truncate int64 to int32

  # Both sides are LLVM land values -> resolve_binary_llvm_values
  # LLVM::Int32 and LLVM::Int32
  # LLVM::Int32 and LLVM::Double
  # LLVM::Double and LLVM::Int32
  # LLVM::Double and LLVM::Double
  # LLVM::Int8.pointer and LLVM::Int8.pointer
  # LLVM::Int8.pointer and LLVM::Int32
  # LLVM::Int1 and LLVM::Int1

  # Left side is LLVM land value -> resolve_binary_left_llvm
  # LLVM::Int32 and Int32
  # LLVM::Int32 and Float64
  # LLVM::Double and Int32
  # LLVM::Double and Float64
  # LLVM::Int8.pointer and String
  # LLVM::Int8.pointer and Int32
  # LLVM::Int1 and Bool

  # Right side is LLVM land value -> resolve_binary_right_llvm
  # Int32 and LLVM::Int32
  # Int32 and LLVM::Double
  # Float64 and LLVM::Int32
  # Float64 and LLVM::Double
  # String and LLVM::Int8.pointer
  # String and LLVM::Int32
  # Bool and LLVM::Int1

  # Both sides are compiler known values
  # Int32 and Int32
  # Int32 and Float64
  # Float64 and Int32
  # Float64 and Float64
  # String and String
  # String and Int32
  # Bool and Bool

  def resolve_value(state : ProgramState) : Nil
    lhs = @children[0].resolved_value
    rhs = @children[1].resolved_value

    if lhs.is_a?(LLVM::Value) && rhs.is_a?(LLVM::Value)
      resolve_binary_llvm_values state, lhs, rhs
    elsif lhs.is_a?(LLVM::Value)
      resolve_binary_left_llvm state, lhs, rhs
    elsif rhs.is_a?(LLVM::Value)
      resolve_binary_right_llvm state, lhs, rhs
    elsif lhs.is_a?(Int32) && rhs.is_a?(Int32)
      resolve_binary_integers state, lhs, rhs
    elsif lhs.is_a?(Float64) && rhs.is_a?(Float64)
      resolve_binary_floats state, lhs, rhs
    elsif lhs.is_a?(Float64) && rhs.is_a?(Int32)
      resolve_binary_float_int state, lhs, rhs
    elsif lhs.is_a?(Int32) && rhs.is_a?(Float64)
      resolve_binary_int_float state, lhs, rhs
    elsif lhs.is_a?(String) && rhs.is_a?(String)
      resolve_binary_strings state, lhs, rhs
    elsif lhs.is_a?(String) && rhs.is_a?(Int32)
      resolve_binary_string_int state, lhs, rhs
    elsif lhs.is_a?(Bool) && rhs.is_a?(Bool)
      resolve_binary_bools state, lhs, rhs
    else
      raise EmeraldValueResolutionException.new "Undefined operation #{@value} based on types LHS -> #{lhs} RHS -> #{rhs}", @line, @position
    end
  end

  def resolve_binary_llvm_values(state : ProgramState, lhs, rhs) : Nil
    case lhs.type
    when state.ctx.int32
      if rhs.type == state.ctx.int32
        resolve_binary_int32s state, lhs, rhs
      elsif rhs.type == state.ctx.double
        resolve_binary_int32_double state, lhs, rhs
      else
        raise EmeraldValueResolutionException.new "Undefined operation #{@value} for rhs type (BOTH = LLVM::Value) #{lhs} #{rhs}", @line, @position
      end
    when state.ctx.int1
      if rhs.type == state.ctx.int1
        resolve_binary_int1s state, lhs, rhs
      else
        raise EmeraldValueResolutionException.new "Undefined operation #{@value} for rhs type (BOTH = LLVM::Value) #{lhs} #{rhs}", @line, @position
      end
    when state.ctx.void_pointer
      if rhs.type == state.ctx.void_pointer
        resolve_binary_int8pointers state, lhs, rhs
      elsif rhs.type == state.ctx.int32
        resolve_binary_int8pointer_int32 state, lhs, rhs
      else
        raise EmeraldValueResolutionException.new "Undefined operation #{@value} for rhs type (BOTH = LLVM::Value) #{lhs} #{rhs}", @line, @position
      end
    when state.ctx.double
      if rhs.type == state.ctx.double
        resolve_binary_doubles state, lhs, rhs
      elsif rhs.type == state.ctx.int32
        resolve_binary_double_int32 state, lhs, rhs
      else
        raise EmeraldValueResolutionException.new "Undefined operation #{@value} for rhs type (BOTH = LLVM::Value) #{lhs} #{rhs}", @line, @position
      end
    else
      raise EmeraldValueResolutionException.new "Undefined operation #{@value} for lhs type (BOTH = LLVM::Value) #{lhs} #{rhs}", @line, @position
    end
  end

  def resolve_binary_left_llvm(state : ProgramState, lhs, rhs) : Nil
    case lhs.type
    when state.ctx.int32
      if rhs.is_a?(Int32)
        resolve_binary_int32_int state, lhs, rhs
      elsif rhs.is_a?(Float64)
        resolve_binary_int32_float state, lhs, rhs
      else
        raise EmeraldValueResolutionException.new "Undefined operation #{@value} for rhs type (LHS = LLVM::Value) #{lhs} #{rhs}", @line, @position
      end
    when state.ctx.int1
      if rhs.is_a?(Bool)
        resolve_binary_int1_bool state, lhs, rhs
      else
        raise EmeraldValueResolutionException.new "Undefined operation #{@value} for rhs type (LHS = LLVM::Value) #{lhs} #{rhs}", @line, @position
      end
    when state.ctx.void_pointer
      if rhs.is_a?(String)
        resolve_binary_int8pointer_string state, lhs, rhs
      elsif rhs.is_a?(Int32)
        resolve_binary_int8pointer_int state, lhs, rhs
      else
        raise EmeraldValueResolutionException.new "Undefined operation #{@value} for rhs type (LHS = LLVM::Value) #{lhs} #{rhs}", @line, @position
      end
    when state.ctx.double
      if rhs.is_a?(Float64)
        resolve_binary_double_float state, lhs, rhs
      elsif rhs.is_a?(Int32)
        resolve_binary_double_int state, lhs, rhs
      else
        raise EmeraldValueResolutionException.new "Undefined operation #{@value} for rhs type (LHS = LLVM::Value) #{lhs} #{rhs}", @line, @position
      end
    else
      raise EmeraldValueResolutionException.new "Undefined operation #{@value} for lhs type (LHS = LLVM::Value) #{lhs} #{rhs}", @line, @position
    end
  end

  def resolve_binary_right_llvm(state : ProgramState, lhs, rhs) : Nil
    if lhs.is_a?(Int32)
      if rhs.type == state.ctx.int32
        resolve_binary_int_int32 state, lhs, rhs
      elsif rhs.type == state.ctx.double
        resolve_binary_int_double state, lhs, rhs
      else
        raise EmeraldValueResolutionException.new "Undefined operation #{@value} for rhs type (RHS = LLVM::Value) #{lhs} #{rhs}", @line, @position
      end
    elsif lhs.is_a?(Bool)
      if rhs.type == state.ctx.int1
        resolve_binary_bool_int1 state, lhs, rhs
      else
        raise EmeraldValueResolutionException.new "Undefined operation #{@value} for rhs type (RHS = LLVM::Value) #{lhs} #{rhs}", @line, @position
      end
    elsif lhs.is_a?(Float64)
      if rhs.type == state.ctx.double
        resolve_binary_float_double state, lhs, rhs
      elsif rhs.type == state.ctx.int32
        resolve_binary_float_int32 state, lhs, rhs
      else
        raise EmeraldValueResolutionException.new "Undefined operation #{@value} for rhs type (RHS = LLVM::Value) #{lhs} #{rhs}", @line, @position
      end
    elsif lhs.is_a?(String)
      if rhs.type == state.ctx.void_pointer
        resolve_binary_string_int8pointer state, lhs, rhs
      elsif rhs.type == state.ctx.int32
        resolve_binary_string_int32 state, lhs, rhs
      else
        raise EmeraldValueResolutionException.new "Undefined operation #{@value} for rhs type (RHS = LLVM::Value) #{lhs} #{rhs}", @line, @position
      end
    else
      raise EmeraldValueResolutionException.new "Undefined operation #{@value} for lhs type (RHS = LLVM::Value) #{lhs} #{rhs}", @line, @position
    end
  end

  def resolve_binary_int32s(state : ProgramState, lhs, rhs) : Nil
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

  def resolve_binary_int32_double(state : ProgramState, lhs, rhs) : Nil
    lhs_val = state.builder.si2fp lhs, state.ctx.double
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
  end

  def resolve_binary_int1s(state : ProgramState, lhs, rhs) : Nil
    case @value
    when "!="
      @resolved_value = state.builder.icmp LLVM::IntPredicate::NE, lhs, rhs
    when "=="
      @resolved_value = state.builder.icmp LLVM::IntPredicate::EQ, lhs, rhs
    end
  end

  def resolve_binary_int8pointers(state : ProgramState, lhs, rhs) : Nil
    case @value
    when "!="
      @resolved_value = state.builder.icmp LLVM::IntPredicate::NE, lhs, rhs
    when "=="
      @resolved_value = state.builder.icmp LLVM::IntPredicate::EQ, lhs, rhs
    when "+"
      @resolved_value = state.builder.call state.mod.functions["concatenate:str"], [lhs, rhs], "str_cat"
    end
  end

  def resolve_binary_int8pointer_int32(state : ProgramState, lhs, rhs) : Nil
    if @value == "*"
      @resolved_value = state.builder.call state.mod.functions["repetition:str"], [lhs, rhs], "str_rep"
    end
  end

  def resolve_binary_doubles(state : ProgramState, lhs, rhs) : Nil
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
  end

  def resolve_binary_double_int32(state : ProgramState, lhs, rhs) : Nil
    rhs_val = state.builder.si2fp rhs, state.ctx.double
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
  end

  def resolve_binary_int32_int(state : ProgramState, lhs, rhs) : Nil
    case @value
    when "*"
      @resolved_value = state.builder.mul lhs, state.ctx.int32.const_int(rhs.as(Int32))
    when "/"
      @resolved_value = state.builder.sdiv lhs, state.ctx.int32.const_int(rhs.as(Int32))
    when "+"
      @resolved_value = state.builder.add lhs, state.ctx.int32.const_int(rhs.as(Int32))
    when "-"
      @resolved_value = state.builder.sub lhs, state.ctx.int32.const_int(rhs.as(Int32))
    when "<"
      @resolved_value = state.builder.icmp LLVM::IntPredicate::ULT, lhs, state.ctx.int32.const_int(rhs.as(Int32))
    when ">"
      @resolved_value = state.builder.icmp LLVM::IntPredicate::UGT, lhs, state.ctx.int32.const_int(rhs.as(Int32))
    when "!="
      @resolved_value = state.builder.icmp LLVM::IntPredicate::NE, lhs, state.ctx.int32.const_int(rhs.as(Int32))
    when "=="
      @resolved_value = state.builder.icmp LLVM::IntPredicate::EQ, lhs, state.ctx.int32.const_int(rhs.as(Int32))
    when "<="
      @resolved_value = state.builder.icmp LLVM::IntPredicate::ULE, lhs, state.ctx.int32.const_int(rhs.as(Int32))
    when ">="
      @resolved_value = state.builder.icmp LLVM::IntPredicate::UGE, lhs, state.ctx.int32.const_int(rhs.as(Int32))
    end
  end

  def resolve_binary_int32_float(state : ProgramState, lhs, rhs) : Nil
    lhs_val = state.builder.si2fp lhs, state.ctx.double
    rhs_val = state.ctx.double.const_double(rhs)
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
  end

  def resolve_binary_int1_bool(state : ProgramState, lhs, rhs) : Nil
    if rhs == true
      rhs_val = state.ctx.int1.const_int(1)
    else
      rhs_val = state.ctx.int1.const_int(0)
    end
    case @value
    when "!="
      @resolved_value = state.builder.icmp LLVM::IntPredicate::NE, lhs, rhs_val
    when "=="
      @resolved_value = state.builder.icmp LLVM::IntPredicate::EQ, lhs, rhs_val
    end
  end

  def resolve_binary_int8pointer_string(state : ProgramState, lhs, rhs) : Nil
    rhs_val = state.define_or_find_global rhs
    case @value
    when "!="
      @resolved_value = state.builder.icmp LLVM::IntPredicate::NE, lhs, rhs_val
    when "=="
      @resolved_value = state.builder.icmp LLVM::IntPredicate::EQ, lhs, rhs_val
    when "+"
      @resolved_value = state.builder.call state.mod.functions["concatenate:str"], [lhs, rhs_val], "str_cat"
    end
  end

  def resolve_binary_int8pointer_int(state : ProgramState, lhs, rhs) : Nil
    if @value == "*"
      rhs_val = state.ctx.int32.const_int(rhs)
      @resolved_value = state.builder.call state.mod.functions["repetition:str"], [lhs, rhs_val], "str_rep"
    end
  end

  def resolve_binary_double_float(state : ProgramState, lhs, rhs) : Nil
    rhs_val = state.ctx.double.const_double(rhs)
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
  end

  def resolve_binary_double_int(state : ProgramState, lhs, rhs) : Nil
    rhs_val = state.ctx.double.const_double(rhs.to_f)
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
  end

  def resolve_binary_int_int32(state : ProgramState, lhs, rhs) : Nil
    lhs_val = state.ctx.int32.const_int(lhs.as(Int32))
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
  end

  def resolve_binary_int_double(state : ProgramState, lhs, rhs) : Nil
    lhs_val = state.ctx.double.const_double(lhs.to_f)
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
  end

  def resolve_binary_bool_int1(state : ProgramState, lhs, rhs) : Nil
    if lhs == true
      lhs_val = state.ctx.int1.const_int(1)
    else
      lhs_val = state.ctx.int1.const_int(0)
    end
    case @value
    when "!="
      @resolved_value = state.builder.icmp LLVM::IntPredicate::NE, lhs_val, rhs
    when "=="
      @resolved_value = state.builder.icmp LLVM::IntPredicate::EQ, lhs_val, rhs
    end
  end

  def resolve_binary_float_double(state : ProgramState, lhs, rhs) : Nil
    lhs_val = state.ctx.double.const_double(lhs)
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
  end

  def resolve_binary_float_int32(state : ProgramState, lhs, rhs) : Nil
    lhs_val = state.ctx.double.const_double(lhs)
    rhs_val = state.builder.si2fp rhs, state.ctx.double
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
  end

  def resolve_binary_string_int8pointer(state : ProgramState, lhs, rhs) : Nil
    lhs_val = state.define_or_find_global lhs
    case @value
    when "!="
      @resolved_value = state.builder.icmp LLVM::IntPredicate::NE, lhs_val, rhs
    when "=="
      @resolved_value = state.builder.icmp LLVM::IntPredicate::EQ, lhs_val, rhs
    when "+"
      @resolved_value = state.builder.call state.mod.functions["concatenate:str"], [lhs_val, rhs], "str_cat"
    end
  end

  def resolve_binary_string_int32(state : ProgramState, lhs, rhs) : Nil
    if @value == "*"
      lhs_val = state.define_or_find_global lhs
      @resolved_value = state.builder.call state.mod.functions["repetition:str"], [lhs_val, rhs], "str_rep"
    end
  end

  def resolve_binary_integers(state : ProgramState, lhs, rhs) : Nil
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
  end

  def resolve_binary_floats(state : ProgramState, lhs, rhs) : Nil
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
  end

  def resolve_binary_float_int(state : ProgramState, lhs, rhs) : Nil
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
  end

  def resolve_binary_int_float(state : ProgramState, lhs, rhs) : Nil
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
  end

  def resolve_binary_strings(state : ProgramState, lhs, rhs) : Nil
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
  end

  def resolve_binary_string_int(state : ProgramState, lhs, rhs) : Nil
    case @value
    when "*"
      @resolved_value = lhs * rhs
    else
      raise EmeraldValueResolutionException.new "Undefined operation #{@value} on string \"#{lhs}\" and int32 #{rhs}", @line, @position
    end
  end

  def resolve_binary_bools(state : ProgramState, lhs, rhs) : Nil
    case @value
    when "=="
      @resolved_value = lhs == rhs
    when "!="
      @resolved_value = lhs != rhs
    else
      raise EmeraldValueResolutionException.new "Undefined operation #{@value} on boolean values #{lhs} #{rhs}", @line, @position
    end
  end
end
