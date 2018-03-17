class FunctionDeclarationNode < Node
  getter params, return_type

  def initialize(@name : String, @params : Hash(String, Symbol), @return_type : Symbol, @line : Int32, @position : Int32)
    @value = nil
    @children = [] of Node
  end

  def pre_walk(state : ProgramState) : Nil
    # Save reference to active block
    state.saved_block = state.active_block
    # Get LLVM Parameter type(s)
    params = [] of LLVM::Type
    param_names = [] of String
    @params.each do |name, type_val|
      params.push state.symbol_to_llvm type_val
      param_names.push name
    end
    # Get LLVM return type
    return_sig = state.symbol_to_llvm @return_type
    # Generate function, using types
    func = state.mod.functions.add @name, params, return_sig
    # Generated function is now active
    state.active_function = func
    state.active_function_name = @name
    # Add function params to module state under function
    array = func.params.to_a
    array.each_with_index do |param, i|
      state.add_variable func, param_names[i], param
    end
  end

  def implicit_return_node : Node
    @children[0].children[-1]
  end

  def resolve_value(state : ProgramState) : Nil
    if implicit_return_node.class != ReturnNode
      if implicit_return_node.class == IfExpressionNode && implicit_return_node.as(IfExpressionNode).uses_exit == false
      else
        state.builder.position_at_end state.active_block
        case @return_type
        when :Nil
          state.builder.ret
        when :Int32
          resolve_int32_func state
        when :Int64
          resolve_int64_func state
        when :Float64
          resolve_float64_func state
        when :Bool
          resolve_bool_func state
        when :String
          resolve_string_func state
        end
      end
    end

    # Return to saved block and make resume main as active function
    state.active_function = state.mod.functions["main"]
    state.active_block = state.saved_block
  end

  def resolve_int32_func(state : ProgramState) : Nil
    if implicit_return_node.resolved_value.is_a?(Int32)
      state.builder.ret state.gen_int32(implicit_return_node.resolved_value.as(Int32))
    elsif implicit_return_node.resolved_value.is_a?(LLVM::Value)
      if implicit_return_node.resolved_value.as(LLVM::Value).type == state.int32
        state.builder.ret implicit_return_node.resolved_value.as(LLVM::Value)
      else
        raise value_exception "integer"
      end
    else
      raise value_exception "integer"
    end
  end

  def resolve_int64_func(state : ProgramState) : Nil
    if implicit_return_node.resolved_value.is_a?(LLVM::Value)
      if implicit_return_node.resolved_value.as(LLVM::Value).type == state.int64
        state.builder.ret implicit_return_node.resolved_value.as(LLVM::Value)
      else
        raise value_exception "integer64"
      end
    else
      raise value_exception "integer64"
    end
  end

  def resolve_float64_func(state : ProgramState) : Nil
    if implicit_return_node.resolved_value.is_a?(Float64)
      state.builder.ret state.gen_double(implicit_return_node.resolved_value.as(Float64))
    elsif implicit_return_node.resolved_value.is_a?(LLVM::Value)
      if implicit_return_node.resolved_value.as(LLVM::Value).type == state.double
        state.builder.ret implicit_return_node.resolved_value.as(LLVM::Value)
      else
        raise value_exception "float"
      end
    else
      raise value_exception "float"
    end
  end

  def resolve_bool_func(state : ProgramState) : Nil
    if implicit_return_node.resolved_value.is_a?(Bool)
      implicit_return_node.resolved_value.as(Bool) ? state.builder.ret state.gen_int1(1) : state.builder.ret state.gen_int1(0)
    elsif implicit_return_node.resolved_value.is_a?(LLVM::Value)
      if implicit_return_node.resolved_value.as(LLVM::Value).type == state.int1
        state.builder.ret implicit_return_node.resolved_value.as(LLVM::Value)
      else
        raise value_exception "bool"
      end
    else
      raise value_exception "bool"
    end
  end

  def resolve_string_func(state : ProgramState) : Nil
    if implicit_return_node.resolved_value.is_a?(String)
      state.builder.ret state.define_or_find_global implicit_return_node.resolved_value.as(String)
    elsif implicit_return_node.resolved_value.is_a?(LLVM::Value)
      if implicit_return_node.resolved_value.as(LLVM::Value).type == state.void_pointer
        state.builder.ret implicit_return_node.resolved_value.as(LLVM::Value)
      else
        raise value_exception "string"
      end
    else
      raise value_exception "string"
    end
  end

  def value_exception(expected_type : String) : EmeraldValueResolutionException
    EmeraldValueResolutionException.new "#{@name} function requires an explicit or implicit #{expected_type} return", @line, @position
  end
end
