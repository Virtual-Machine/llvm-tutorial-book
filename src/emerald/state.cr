class ProgramState
  getter variables, variable_pointers, globals, builder, mod, blocks, close_statements, ctx
  property! active_block, active_function, active_function_name, saved_block
  property printAST, printResolutions

  @active_block : LLVM::BasicBlock?
  @saved_block : LLVM::BasicBlock?
  @active_function : LLVM::Function?

  def initialize(@builder : LLVM::Builder, @ctx : LLVM::Context, @mod : LLVM::Module, @block : LLVM::BasicBlock)
    @globals = {} of String => LLVM::Value
    @variables = {} of LLVM::Function => Hash(String, LLVM::Value)
    @variable_pointers = {} of LLVM::Function => Hash(String, LLVM::Value)
    @blocks = {} of String => LLVM::BasicBlock
    @printAST = false
    @printResolutions = false
    @active_function = mod.functions["main"]
    @active_function_name = "main"
    @active_block = block
    @saved_block = nil
    add_block("main_body", block)
    active_function.linkage = LLVM::Linkage::External
    declare_standard_functions
    builder.position_at_end block
    @close_statements = [] of CloseStatement
  end

  def declare_standard_functions : Nil
    mod.functions.add "puts:int", [int32], int32
    mod.functions.add "puts:int64", [int64], int64
    mod.functions.add "puts:bool", [int1], int32
    mod.functions.add "puts:float", [double], int32
    mod.functions.add "puts:str", [void_pointer], int32
    mod.functions.add "concatenate:str", [void_pointer, void_pointer], void_pointer
    mod.functions.add "repetition:str", [void_pointer, int32], void_pointer
    mod.functions.add "strlen", [void_pointer], int64
    mod.functions.add "__strncat_chk", [void_pointer, void_pointer, int64, int64], void_pointer
    mod.functions.add "llvm.objectsize.i64.p0i8", [void_pointer, int1], int64
    mod.functions.add "malloc", [int64], void_pointer
    mod.functions.add "realloc", [void_pointer, int64], void_pointer
    mod.functions.add "free", [void_pointer], void
  end

  def close_blocks : Nil
    @close_statements.each do |statement|
      statement.close builder
    end
    builder.position_at_end active_block
    builder.ret gen_int32(0)
  end

  def add_block(name : String, block : LLVM::BasicBlock)
    @blocks[name] = block
  end

  def define_or_find_global(name : String) : LLVM::Value
    if has_global?(name)
      return @globals[name]
    else
      @globals[name] = builder.global_string_pointer name
      return @globals[name]
    end
  end

  def has_global?(name : String) : Bool
    @globals[name]? ? true : false
  end

  def add_variable(func : LLVM::Function, name : String, value : ValueType) : Nil
    builder.position_at_end active_block
    if @variables[func]?
    else
      @variables[func] = {} of String => LLVM::Value
      @variable_pointers[func] = {} of String => LLVM::Value
    end
    allocation_required = (!@variables[func].has_key? name)
    store_variable func, name, value, allocation_required
  end

  def store_variable(func : LLVM::Function, name : String, value : ValueType, allocate : Bool) : Nil
    if value.is_a?(Int32)
      store_int32 func, name, value, allocate
    elsif value.is_a?(Bool)
      store_int1 func, name, value, allocate
    elsif value.is_a?(Float64)
      store_float64 func, name, value, allocate
    elsif value.is_a?(String)
      ptr = define_or_find_global value
      @variables[func][name] = ptr
    else
      if value.is_a?(LLVM::Value)
        @variables[func][name] = value
      else
        raise "Unable to store value of type #{value.class}"
      end
    end
  end

  def store_int32(func : LLVM::Function, name : String, value : ValueType, allocate : Bool) : Nil
    ptr = allocate ? (builder.alloca int32, name) : (@variables[func][name])
    builder.store gen_int32(value), ptr
    @variables[func][name] = ptr
    @variable_pointers[func][name] = ptr if allocate
  end

  def store_int1(func : LLVM::Function, name : String, value : ValueType, allocate : Bool) : Nil
    ptr = allocate ? (builder.alloca int1, name) : (@variables[func][name])
    value ? builder.store gen_int1(1), ptr : builder.store gen_int1(0), ptr
    @variables[func][name] = ptr
    @variable_pointers[func][name] = ptr if allocate
  end

  def store_float64(func : LLVM::Function, name : String, value : ValueType, allocate : Bool) : Nil
    ptr = allocate ? (builder.alloca double, name) : (@variables[func][name])
    builder.store gen_double(value), ptr
    @variables[func][name] = ptr
    @variable_pointers[func][name] = ptr if allocate
  end

  def reference_variable(func : LLVM::Function, name : String, line : Int32, column : Int32) : LLVM::Value
    if pointer_exists? func, name
      builder.position_at_end active_block
      return builder.load @variable_pointers[func][name]
    elsif variable_exists? func, name
      type_val = variables[func][name].type
      builder.position_at_end active_block
      if type_val == void_pointer || type_val == int1 || type_val == int32 || type_val == double
        return @variables[func][name]
      else
        return builder.load @variables[func][name]
      end
    else
      raise EmeraldVariableReferenceException.new "Undefined variable reference. Trying to lookup #{name}, but its declaration cannot be found.", line, column
    end
  end

  def variable_exists?(func : LLVM::Function, name : String) : Bool
    if @variables[func]?
      if @variables[func].has_key? name
        return true
      end
    end
    return false
  end

  def pointer_exists?(func : LLVM::Function, name : String) : Bool
    if @variable_pointers[func]?
      if @variable_pointers[func].has_key? name
        return true
      end
    end
    return false
  end

  def symbol_to_llvm(symbol : Symbol) : LLVM::Type
    case symbol
    when :Int32
      return int32
    when :Int64
      return int64
    when :Float64
      return double
    when :Bool
      return int1
    when :String
      return void_pointer
    when :Nil
      return void
    else
      raise "Undefined case in symbol_to_llvm"
    end
  end

  def crystal_to_llvm(value : ValueType) : LLVM::Value
    if value.is_a?(Bool)
      value ? return gen_int1(1) : return gen_int1(0)
    elsif value.is_a?(Int32)
      return gen_int32(value)
    elsif value.is_a?(Float64)
      return gen_double(value)
    elsif value.is_a?(String)
      return define_or_find_global value
    elsif value.is_a?(LLVM::Value)
      return value
    else
      raise "Unknown value type in crystal_to_llvm function"
    end
  end

  def int32 : LLVM::Type
    return @ctx.int32
  end

  def int64 : LLVM::Type
    return @ctx.int64
  end

  def double : LLVM::Type
    return @ctx.double
  end

  def int1 : LLVM::Type
    return @ctx.int1
  end

  def void_pointer : LLVM::Type
    return @ctx.void_pointer
  end

  def void : LLVM::Type
    return @ctx.void
  end

  def gen_int32(value : Int32) : LLVM::Value
    return @ctx.int32.const_int(value)
  end

  def gen_int64(value : Int64) : LLVM::Value
    return @ctx.int64.const_int(value)
  end

  def gen_int1(value : Int32) : LLVM::Value
    return @ctx.int1.const_int(value)
  end

  def gen_double(value : Float64) : LLVM::Value
    return @ctx.double.const_double(value)
  end
end
