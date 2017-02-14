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
