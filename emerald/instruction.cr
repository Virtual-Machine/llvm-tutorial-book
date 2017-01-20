abstract class Instruction
  abstract def build_instruction(builder : LLVM::Builder)
end

class ComparisonInstruction < Instruction
  getter block, comp, goto1, goto2, state

  def initialize(@state : ProgramState, @block : LLVM::BasicBlock, @comp : LLVM::Value, @goto1 : LLVM::BasicBlock, @goto2 : LLVM::BasicBlock, @line : Int32, @position : Int32)
  end

  def build_instruction(builder : LLVM::Builder)
    builder.position_at_end block
    builder.cond comp, goto1, goto2
  end

  def to_s
    origin_block = state.get_block_name block
    goto1_block = state.get_block_name goto1
    goto2_block = state.get_block_name goto2
    if comp.to_value.to_s == "i1 true"
      "#{self.class} Jump to #{goto1_block}, reject #{goto2_block}  in  #{origin_block}"
    else
      "#{self.class} Jump to #{goto2_block}, reject #{goto1_block}  in  #{origin_block}"
    end
  end
end

class JumpInstruction < Instruction
  getter block, goto, state

  def initialize(@state : ProgramState, @block : LLVM::BasicBlock, @goto : LLVM::BasicBlock, @line : Int32, @position : Int32)
  end

  def build_instruction(builder : LLVM::Builder)
    builder.position_at_end block
    builder.br goto
  end

  def to_s
    origin_block = state.get_block_name block
    goto_block = state.get_block_name goto
    "#{self.class} Jump to #{goto_block}  in  #{origin_block}"
  end
end

class CallInstruction < Instruction
  getter params, block, state

  def initialize(@state : ProgramState, @block : LLVM::BasicBlock, @func : LLVM::Function, @params : Array(LLVM::Value), @name : String, @line : Int32, @position : Int32)
  end

  def build_instruction(builder : LLVM::Builder)
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
        origin_block = state.get_block_name block
        "#{self.class} - #{@func.name} - #{found}  in  #{origin_block}"
      end
    else
      origin_block = state.get_block_name block
      "#{self.class} - #{@func.name}  in  #{origin_block}"
    end
  end
end

class ReturnInstruction < Instruction
  getter block, state

  def initialize(@state : ProgramState, @block : LLVM::BasicBlock, @value : ValueType, @return_type : String, @name : String, @line : Int32, @position : Int32)
  end

  def build_instruction(builder : LLVM::Builder)
    builder.position_at_end block
    case @return_type
    when "Void"
      builder.ret
    when "Int32"
      builder.ret LLVM.int(LLVM::Int32, @value.as(Int32))
    end
  end

  def to_s
    origin_block = state.get_block_name block
    "#{self.class} - #{@value}  in  #{origin_block}"
  end
end
