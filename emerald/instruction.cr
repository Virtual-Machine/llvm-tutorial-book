abstract class Instruction
  abstract def build_instruction(builder : LLVM::Builder, state : ProgramState)
end

class CallInstruction < Instruction
  def initialize(@func : LLVM::Function, @params : Array(LLVM::Value), @name : String)
  end

  def build_instruction(builder : LLVM::Builder, state : ProgramState)
    if @func.name == "puts" # Builtin puts command
      matches = @params.inspect.scan /c"(.*)\\00"\]/
      found = matches[0][1]?
      if found.is_a?(String)
        if state.has_global? found
          string_ptr = state.globals[found]
          builder.call @func, string_ptr, @name
        else
          string_ptr = builder.global_string_pointer found, "puts_pointer"
          state.add_global found, string_ptr
          builder.call @func, string_ptr, @name
        end
      else
        raise "EMERALD ERROR: There was an error building the instruction for Call Instruction - puts
Unable to resolve parameter into valid string"
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
  def initialize(@value : ValueType, @return_type : String, @name : String)
  end

  def build_instruction(builder : LLVM::Builder, state : ProgramState)
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
