class ProgramState
  getter variables, functions, blocks, instructions, globals
  property! active_block
  property printAST, printResolutions

  @active_block : LLVM::BasicBlock?

  def initialize
    @globals = {} of String => LLVM::Value
    @variables = {} of String => ValueType
    @functions = {} of String => LLVM::Function
    @blocks = {} of String => LLVM::BasicBlock
    @instructions = [] of Instruction
    @printAST = false
    @printResolutions = false
    @active_block = nil
  end

  def add_global(name : String, value : LLVM::Value)
    @globals[name] = value
  end

  def has_global?(name : String) : Bool
    @globals[name]? ? true : false
  end

  def add_variable(name : String, value : ValueType)
    @variables[name] = value
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

  def add_function(name : String, func : LLVM::Function)
    @functions[name] = func
  end

  def add_instruction(instruction : Instruction)
    @instructions.push instruction
  end

  def reference_variable(name : String, line : Int32, column : Int32) : ValueType
    if variable_exists? name
      return @variables[name]
    else
      raise EmeraldVariableReferenceException.new "Undefined variable reference. Trying to lookup #{name}, but its declaration cannot be found.", line, column
    end
  end

  macro define_exists?(state_type)
  	{% for state in state_type %}
	  	def {{state}}_exists?({{state}} : String) : Bool
			  if @{{state}}s[{{state}}]? != nil
			    return true
			  else
			    return false
			  end
			end
	  {% end %}
	end

  define_exists? [variable, function, block]
end
