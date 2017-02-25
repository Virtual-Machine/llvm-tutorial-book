class CallExpressionNode < Node
  def initialize(@value : ValueType, @line : Int32, @position : Int32)
    @children = [] of Node
  end

  def resolve_value(state : ProgramState) : Nil
    state.builder.position_at_end state.active_block
    if @value.as(String) == "puts"
      @resolved_value = @children[0].resolved_value
      test = @resolved_value
      if test.is_a?(LLVM::Value)
        case test.type
        when state.int64
          state.builder.call state.mod.functions["puts:int64"], test, @value.as(String)
        when state.int32
          state.builder.call state.mod.functions["puts:int"], test, @value.as(String)
        when state.double
          state.builder.call state.mod.functions["puts:float"], test, @value.as(String)
        when state.int1
          state.builder.call state.mod.functions["puts:bool"], test, @value.as(String)
        when state.void_pointer
          state.builder.call state.mod.functions["puts:str"], test, @value.as(String)
        end
      else
        str_pointer = state.define_or_find_global test.to_s
        state.builder.call state.mod.functions["puts:str"], str_pointer, @value.as(String)
      end
    else
      num_params = @children.size
      if num_params == 0
        if state.mod.functions[@value.as(String)].return_type == state.void
          @resolved_value = state.builder.call state.mod.functions[@value.as(String)]
        else
          @resolved_value = state.builder.call state.mod.functions[@value.as(String)], @value.as(String)
        end
      else
        params = [] of LLVM::Value
        @children.each do |child|
          current_value = child.resolved_value
          if current_value.is_a?(Array(LLVM::Value))
            current_value.each do |value|
              params.push value
            end
          else
            params.push state.crystal_to_llvm child.resolved_value
          end
        end
        if state.mod.functions[@value.as(String)].return_type == state.void
          @resolved_value = state.builder.call state.mod.functions[@value.as(String)], params
        else
          @resolved_value = state.builder.call state.mod.functions[@value.as(String)], params, @value.as(String)
        end
      end
    end
  end
end
