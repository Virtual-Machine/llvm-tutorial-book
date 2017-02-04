class FunctionDeclarationNode < Node
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
