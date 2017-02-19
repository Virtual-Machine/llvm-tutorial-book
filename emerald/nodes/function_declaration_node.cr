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
      params.push symbol_to_llvm type_val
      param_names.push name
    end
    return_sig = symbol_to_llvm @return_type
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
      state.builder.position_at_end state.active_block
      case @return_type
      when :Nil
        state.builder.ret
      when :Int32
        if @children[0].children[-1].resolved_value.is_a?(Int32)
          state.builder.ret LLVM.int(LLVM::Int32, @children[0].children[-1].resolved_value.as(Int32))
        elsif @children[0].children[-1].resolved_value.is_a?(LLVM::Value)
          if @children[0].children[-1].resolved_value.as(LLVM::Value).type == LLVM::Int32
            state.builder.ret @children[0].children[-1].resolved_value.as(LLVM::Value)
          else
            raise "#{@name} function requires an explicit or implicit integer return"
          end
        else
          raise "#{@name} function requires an explicit or implicit integer return"
        end
      when :Int64
        if @children[0].children[-1].resolved_value.is_a?(LLVM::Value)
          if @children[0].children[-1].resolved_value.as(LLVM::Value).type == LLVM::Int64
            state.builder.ret @children[0].children[-1].resolved_value.as(LLVM::Value)
          else
            raise "#{@name} function requires an explicit or implicit integer64 return"
          end
        else
          raise "#{@name} function requires an explicit or implicit integer64 return"
        end
      when :Float64
        if @children[0].children[-1].resolved_value.is_a?(Float64)
          state.builder.ret LLVM.double(@children[0].children[-1].resolved_value.as(Float64))
        elsif @children[0].children[-1].resolved_value.is_a?(LLVM::Value)
          if @children[0].children[-1].resolved_value.as(LLVM::Value).type == LLVM::Double
            state.builder.ret @children[0].children[-1].resolved_value.as(LLVM::Value)
          else
            raise "#{@name} function requires an explicit or implicit float return"
          end
        else
          raise "#{@name} function requires an explicit or implicit float return"
        end
      when :Bool
        if @children[0].children[-1].resolved_value.is_a?(Bool)
          if @children[0].children[-1].resolved_value.as(Bool) == true
            state.builder.ret LLVM.int(LLVM::Int1, 1)
          else
            state.builder.ret LLVM.int(LLVM::Int1, 0)
          end
        elsif @children[0].children[-1].resolved_value.is_a?(LLVM::Value)
          if @children[0].children[-1].resolved_value.as(LLVM::Value).type == LLVM::Int1
            state.builder.ret @children[0].children[-1].resolved_value.as(LLVM::Value)
          else
            raise "#{@name} function requires an explicit or implicit bool return"
          end
        else
          raise "#{@name} function requires an explicit or implicit bool return"
        end
      when :String
        if @children[0].children[-1].resolved_value.is_a?(String)
          state.builder.ret state.define_or_find_global @children[0].children[-1].resolved_value.as(String)
        elsif @children[0].children[-1].resolved_value.is_a?(LLVM::Value)
          if @children[0].children[-1].resolved_value.as(LLVM::Value).type == LLVM::Int8.pointer
            state.builder.ret @children[0].children[-1].resolved_value.as(LLVM::Value)
          else
            raise "#{@name} function requires an explicit or implicit bool return"
          end
        else
          raise "#{@name} function requires an explicit or implicit bool return"
        end
      end
    end
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
    when :Nil
      return LLVM::Void
    else
      raise "Undefined case in symbol_to_llvm"
    end
  end
end
