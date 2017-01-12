abstract class Instruction
  abstract def build_instruction(builder : LLVM::Builder)
end

class CallInstruction < Instruction
  def initialize(@func : LLVM::Function, @params : Array(LLVM::Value), @name : String)
  end

  def build_instruction(builder : LLVM::Builder)
    if @func.name == "puts" # Builtin puts command
      matches = @params.inspect.scan /c"(.*)\\00"\]/
      found = matches[0][1]?
      if found.is_a?(String)
        string_ptr = builder.global_string_pointer found, "puts_pointer"
        builder.call @func, string_ptr, @name
      else
        raise "String value not found for puts"
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
end
