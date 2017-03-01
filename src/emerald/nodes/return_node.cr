class ReturnNode < Node
  def initialize(@line : Int32, @position : Int32)
    @value = nil
    @children = [] of Node
  end

  def resolve_value(state : ProgramState) : Nil
    func_decl = get_func_decl
    expected_ret = func_decl.return_type
    @resolved_value = @children[0].resolved_value
    test = @resolved_value
    state.builder.position_at_end state.active_block
    if test.is_a?(LLVM::Value)
      state.builder.ret test
    elsif test.is_a?(Bool)
      test ? state.builder.ret state.gen_int1(1) : state.builder.ret state.gen_int1(0)
    elsif test.is_a?(String)
      str_pointer = state.define_or_find_global test
      state.builder.ret str_pointer
    elsif test.is_a?(Int32)
      if expected_ret == :Int32
        state.builder.ret state.gen_int32(test)
      elsif expected_ret == :Int64
        state.builder.ret state.gen_int64(test.to_i64)
      else
        raise "Invalid return for expected return type #{expected_ret}"
      end
    elsif test.is_a?(Int64)
      state.builder.ret state.gen_int64(test)
    elsif test.is_a?(Float64)
      state.builder.ret state.gen_double(test)
    elsif test.nil?
      state.builder.ret
    end
  end
end
