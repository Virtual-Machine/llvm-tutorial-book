class ProgramState
  getter variables, functions, blocks, instructions

  def initialize
    @variables = {} of String => ValueType
    @functions = {} of String => LLVM::Function
    @blocks = {} of String => LLVM::BasicBlock
    @instructions = [] of Instruction
  end

  def add_variable(name : String, value : ValueType)
    @variables[name] = value
  end

  def add_block(name : String, block : LLVM::BasicBlock)
    @blocks[name] = block
  end

  def add_function(name : String, func : LLVM::Function)
    @functions[name] = func
  end

  def add_instruction(instruction : Instruction)
    @instructions.push instruction
  end

  def reference_variable(name : String) : ValueType
    if variable_exists? name
      return @variables[name]
    else
      raise "Undefined variable reference. Trying to lookup #{name}, but its declaration cannot be found."
    end
  end

  macro define_exists?(state_type)
  	{% for state in state_type %}
	  	def {{state}}_exists?({{state}} : String) : Bool
			  if @{{state}}s[{{state}}]
			    return true
			  else
			    return false
			  end
			end
	  {% end %}
	end

  define_exists? [variable, function, block]
end
