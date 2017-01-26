class ProgramState
  getter variables, globals, builder, mod, blocks, close_statements
  property! active_block, active_function, active_block_name, active_function_name
  property printAST, printResolutions

  @active_block : LLVM::BasicBlock?
  @active_function : LLVM::Function?

  def initialize(@builder : LLVM::Builder, @mod : LLVM::Module, @block : LLVM::BasicBlock)
    @globals = {} of String => LLVM::Value
    @variables = {} of LLVM::Function => Hash(String, LLVM::Value)
    @blocks = {} of String => LLVM::BasicBlock
    @printAST = false
    @printResolutions = false
    @active_function = mod.functions["main"]
    @active_function_name = "main"
    @active_block = block
    @active_block_name = "main_body"
    add_block("main_body", block)
    active_function.linkage = LLVM::Linkage::External
    mod.functions.add "puts:int", [LLVM::Int32], LLVM::Int32
    mod.functions.add "puts:bool", [LLVM::Int1], LLVM::Int32
    mod.functions.add "puts:float", [LLVM::Double], LLVM::Int32
    mod.functions.add "puts:str", [LLVM::VoidPointer], LLVM::Int32
    builder.position_at_end block
    @close_statements = [] of CloseStatement
  end

  def close_blocks
    @close_statements.each do |statement|
      statement.close builder
    end
    builder.position_at_end active_block
    builder.ret LLVM.int(LLVM::Int32, 0)
  end

  def set_active_function(name : String) : Nil
    @active_function = mod.functions[name]
    @active_function_name = name
  end

  def set_active_block(name : String) : Nil
    @active_block = @blocks[name]
    @active_block_name = name
  end

  def add_block(name : String, block : LLVM::BasicBlock)
    @blocks[name] = block
  end

  def get_block_name(block : LLVM::BasicBlock) : String?
    @blocks.each do |name, t_block|
      if block == t_block
        return name
      end
    end
    return nil
  end

  def define_or_find_global(name : String) : LLVM::Value
    if has_global?(name)
      return @globals[name]
    else
      @globals[name] = builder.global_string_pointer name
      return @globals[name]
    end
  end

  def add_global(name : String, value : LLVM::Value)
    @globals[name] = value
  end

  def has_global?(name : String) : Bool
    @globals[name]? ? true : false
  end

  def add_variable(func : LLVM::Function, name : String, value : ValueType)
    builder.position_at_end blocks["main_body"]
    if @variables[func]?
      if !@variables[func].has_key? name
        if value.is_a?(Int32)
          ptr = builder.alloca LLVM::Int32, name
          builder.store LLVM.int(LLVM::Int32, value), ptr
          @variables[func][name] = ptr
        elsif value.is_a?(Bool)
          ptr = builder.alloca LLVM::Int1, name
          if value
            builder.store LLVM.int(LLVM::Int1, 1), ptr
          else
            builder.store LLVM.int(LLVM::Int1, 0), ptr
          end
          @variables[func][name] = ptr
        elsif value.is_a?(Float64)
          ptr = builder.alloca LLVM::Double, name
          builder.store LLVM.double(value), ptr
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
    else
      @variables[func] = {} of String => LLVM::Value
      if value.is_a?(Int32)
        ptr = builder.alloca LLVM::Int32, name
        builder.store LLVM.int(LLVM::Int32, value), ptr
        @variables[func][name] = ptr
      end
    end
  end

  def reference_variable(func : LLVM::Function, name : String, line : Int32, column : Int32) : LLVM::Value
    if variable_exists? func, name
      builder.position_at_end active_block
      if @variables[func][name].type == LLVM::Int8.pointer
        # return builder.gep @variables[func][name], LLVM.int(LLVM::Int32, 0), LLVM.int(LLVM::Int32, 0)
        return @variables[func][name]
      elsif @variables[func][name].type == LLVM::Double
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
end
