abstract class Instruction
  abstract def build_instruction(builder : LLVM::Builder, state : ProgramState)
end

class ComparisonInstruction < Instruction
  getter block, comp, goto1, goto2

  def initialize(@block : LLVM::BasicBlock, @comp : LLVM::Value, @goto1 : LLVM::BasicBlock, @goto2 : LLVM::BasicBlock, @line : Int32, @position : Int32)
  end

  def build_instruction(builder : LLVM::Builder, state : ProgramState)
    builder.position_at_end block
    builder.cond comp, goto1, goto2
  end

  def to_s
  end
end

class JumpInstruction < Instruction
  getter block, goto

  def initialize(@block : LLVM::BasicBlock, @goto : LLVM::BasicBlock, @line : Int32, @position : Int32)
  end

  def build_instruction(builder : LLVM::Builder, state : ProgramState)
    builder.position_at_end block
    builder.br goto
  end

  def to_s
  end
end

class CallInstruction < Instruction
  getter params, block

  def initialize(@block : LLVM::BasicBlock, @func : LLVM::Function, @params : Array(LLVM::Value), @name : String, @line : Int32, @position : Int32)
  end

  def build_instruction(builder : LLVM::Builder, state : ProgramState)
    builder.position_at_end block
    if @func.name == "puts" # Builtin puts command
      matches = @params.inspect.scan /c"(.*)\\00"\]/
      found = matches[0][1]?
      if found.is_a?(String)
        found = found.gsub(/\\09/, "\t")
        found = found.gsub(/\\0A/, "\n")
        if state.has_global? found
          string_ptr = state.globals[found]
          builder.call @func, string_ptr, @name
        else
          string_ptr = builder.global_string_pointer found, "puts_pointer"
          state.add_global found, string_ptr
          builder.call @func, string_ptr, @name
        end
      else
        raise EmeraldInstructionException.new "There was an error building the instruction for Call Instruction - puts
Unable to resolve parameter into valid string", @line, @position
      end
    else
      if @params.size == 0
        builder.call @func, @name
      elsif @params.size == 1
        builder.call @func, @params[0], @name
      else
        builder.call @func, @params, @name
      end
    end
  end

  def to_s
    if @func.name == "puts"
      matches = @params.inspect.scan /c"(.*)\\00"\]/
      found = matches[0][1]?
      if found.is_a?(String)
        "#{self.class} - #{@func.name} - #{found}"
      end
    else
      "#{self.class} - #{@func.name}"
    end
  end
end

class ReturnInstruction < Instruction
  getter block

  def initialize(@block : LLVM::BasicBlock, @value : ValueType, @return_type : String, @name : String, @line : Int32, @position : Int32)
  end

  def build_instruction(builder : LLVM::Builder, state : ProgramState)
    builder.position_at_end block
    case @return_type
    when "Void"
      builder.ret
    when "Int32"
      builder.ret LLVM.int(LLVM::Int32, @value.as(Int32))
    end
  end

  def to_s
    "#{self.class} - #{@value}"
  end
end
