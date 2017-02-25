class FunctionDeclarationNode < Node
  getter params

  def initialize(@name : String, @params : Hash(String, Symbol), @return_type : Symbol, @line : Int32, @position : Int32)
    @value = nil
    @children = [] of Node
  end

  def pre_walk(state : ProgramState) : Nil
    state.saved_block = state.active_block
    params = [] of LLVM::Type
    param_names = [] of String
    @params.each do |name, type_val|
      params.push state.symbol_to_llvm type_val
      param_names.push name
    end
    return_sig = state.symbol_to_llvm @return_type
    func = state.mod.functions.add @name, params, return_sig
    state.active_function = func
    state.active_function_name = @name
    array = func.params.to_a
    array.each_with_index do |param, i|
      state.add_variable func, param_names[i], param
    end
  end

  def resolve_value(state : ProgramState) : Nil
    if @children[0].children[-1].class != ReturnNode
      if @children[0].children[-1].class == IfExpressionNode && @children[0].children[-1].as(IfExpressionNode).uses_exit == false
      else
        state.builder.position_at_end state.active_block
        case @return_type
        when :Nil
          state.builder.ret
        when :Int32
          if @children[0].children[-1].resolved_value.is_a?(Int32)
            state.builder.ret state.int32.const_int(@children[0].children[-1].resolved_value.as(Int32))
          elsif @children[0].children[-1].resolved_value.is_a?(LLVM::Value)
            if @children[0].children[-1].resolved_value.as(LLVM::Value).type == state.int32
              state.builder.ret @children[0].children[-1].resolved_value.as(LLVM::Value)
            else
              raise EmeraldValueResolutionException.new "#{@name} function requires an explicit or implicit integer return", @line, @position
            end
          else
            raise EmeraldValueResolutionException.new "#{@name} function requires an explicit or implicit integer return", @line, @position
          end
        when :Int64
          if @children[0].children[-1].resolved_value.is_a?(LLVM::Value)
            if @children[0].children[-1].resolved_value.as(LLVM::Value).type == state.int64
              state.builder.ret @children[0].children[-1].resolved_value.as(LLVM::Value)
            else
              raise EmeraldValueResolutionException.new "#{@name} function requires an explicit or implicit integer64 return", @line, @position
            end
          else
            raise EmeraldValueResolutionException.new "#{@name} function requires an explicit or implicit integer64 return", @line, @position
          end
        when :Float64
          if @children[0].children[-1].resolved_value.is_a?(Float64)
            state.builder.ret state.double.const_double(@children[0].children[-1].resolved_value.as(Float64))
          elsif @children[0].children[-1].resolved_value.is_a?(LLVM::Value)
            if @children[0].children[-1].resolved_value.as(LLVM::Value).type == state.double
              state.builder.ret @children[0].children[-1].resolved_value.as(LLVM::Value)
            else
              raise EmeraldValueResolutionException.new "#{@name} function requires an explicit or implicit float return", @line, @position
            end
          else
            raise EmeraldValueResolutionException.new "#{@name} function requires an explicit or implicit float return", @line, @position
          end
        when :Bool
          if @children[0].children[-1].resolved_value.is_a?(Bool)
            if @children[0].children[-1].resolved_value.as(Bool) == true
              state.builder.ret state.int1.const_int(1)
            else
              state.builder.ret state.int1.const_int(0)
            end
          elsif @children[0].children[-1].resolved_value.is_a?(LLVM::Value)
            if @children[0].children[-1].resolved_value.as(LLVM::Value).type == state.int1
              state.builder.ret @children[0].children[-1].resolved_value.as(LLVM::Value)
            else
              raise EmeraldValueResolutionException.new "#{@name} function requires an explicit or implicit bool return", @line, @position
            end
          else
            raise EmeraldValueResolutionException.new "#{@name} function requires an explicit or implicit bool return", @line, @position
          end
        when :String
          if @children[0].children[-1].resolved_value.is_a?(String)
            state.builder.ret state.define_or_find_global @children[0].children[-1].resolved_value.as(String)
          elsif @children[0].children[-1].resolved_value.is_a?(LLVM::Value)
            if @children[0].children[-1].resolved_value.as(LLVM::Value).type == state.void_pointer
              state.builder.ret @children[0].children[-1].resolved_value.as(LLVM::Value)
            else
              raise EmeraldValueResolutionException.new "#{@name} function requires an explicit or implicit string return", @line, @position
            end
          else
            raise EmeraldValueResolutionException.new "#{@name} function requires an explicit or implicit string return", @line, @position
          end
        end
      end
    end
    state.active_function = state.mod.functions["main"]
    state.active_block = state.saved_block
  end
end
