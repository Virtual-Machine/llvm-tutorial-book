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
    mod.functions.add "puts:int", [@ctx.int32], @ctx.int32
    mod.functions.add "puts:int64", [@ctx.int64], @ctx.int64
    mod.functions.add "puts:bool", [@ctx.int1], @ctx.int32
    mod.functions.add "puts:float", [@ctx.double], @ctx.int32
    mod.functions.add "puts:str", [@ctx.void_pointer], @ctx.int32
    mod.functions.add "concatenate:str", [@ctx.void_pointer, @ctx.void_pointer], @ctx.void_pointer
    mod.functions.add "repetition:str", [@ctx.void_pointer, @ctx.int32], @ctx.void_pointer
    mod.functions.add "strlen", [@ctx.void_pointer], @ctx.int64
    mod.functions.add "__strncat_chk", [@ctx.void_pointer, @ctx.void_pointer, @ctx.int64, @ctx.int64], @ctx.void_pointer
    mod.functions.add "llvm.objectsize.i64.p0i8", [@ctx.void_pointer, @ctx.int1], @ctx.int64
    mod.functions.add "malloc", [@ctx.int64], @ctx.void_pointer
    mod.functions.add "realloc", [@ctx.void_pointer, @ctx.int64], @ctx.void_pointer
    mod.functions.add "free", [@ctx.void_pointer], @ctx.void
  end

  def close_blocks : Nil
    @close_statements.each do |statement|
      statement.close builder
    end
    builder.position_at_end active_block
    builder.ret @ctx.int32.const_int(0)
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
    if !@variables[func].has_key? name
      if value.is_a?(Int32)
        ptr = builder.alloca @ctx.int32, name
        builder.store @ctx.int32.const_int(value), ptr
        @variables[func][name] = ptr
        @variable_pointers[func][name] = ptr
      elsif value.is_a?(Bool)
        ptr = builder.alloca @ctx.int1, name
        if value
          builder.store @ctx.int1.const_int(1), ptr
        else
          builder.store @ctx.int1.const_int(0), ptr
        end
        @variables[func][name] = ptr
        @variable_pointers[func][name] = ptr
      elsif value.is_a?(Float64)
        ptr = builder.alloca @ctx.double, name
        builder.store @ctx.double.const_double(value), ptr
        @variables[func][name] = ptr
        @variable_pointers[func][name] = ptr
      elsif value.is_a?(String)
        ptr = define_or_find_global value
        @variables[func][name] = ptr
      else
        if value.is_a?(LLVM::Value)
          @variables[func][name] = value
        end
      end
    else
      if value.is_a?(Int32)
        ptr = @variables[func][name]
        builder.store @ctx.int32.const_int(value), ptr
        @variables[func][name] = ptr
      elsif value.is_a?(Bool)
        ptr = @variables[func][name]
        if value
          builder.store @ctx.int1.const_int(1), ptr
        else
          builder.store @ctx.int1.const_int(0), ptr
        end
        @variables[func][name] = ptr
      elsif value.is_a?(Float64)
        ptr = @variables[func][name]
        builder.store @ctx.double.const_double(value), ptr
        @variables[func][name] = ptr
      elsif value.is_a?(String)
        ptr = define_or_find_global value
        @variables[func][name] = ptr
      else
        if value.is_a?(LLVM::Value)
          @variables[func][name] = value
        end
      end
    end
  end

  def reference_variable(func : LLVM::Function, name : String, line : Int32, column : Int32) : LLVM::Value
    if pointer_exists? func, name
      builder.position_at_end active_block
      return builder.load @variable_pointers[func][name]
    elsif variable_exists? func, name
      type_val = variables[func][name].type
      builder.position_at_end active_block
      if type_val == @ctx.void_pointer || type_val == @ctx.int1 || type_val == @ctx.int32 || type_val == @ctx.double
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
      return @ctx.int32
    when :Int64
      return @ctx.int64
    when :Float64
      return @ctx.double
    when :Bool
      return @ctx.int1
    when :String
      return @ctx.void_pointer
    when :Nil
      return @ctx.void
    else
      raise "Undefined case in symbol_to_llvm"
    end
  end
end
