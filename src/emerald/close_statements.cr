class CloseStatement
  def close(builder : LLVM::Builder) : Nil
  end
end

class JumpStatement < CloseStatement
  def initialize(@scope : LLVM::BasicBlock, @destination : LLVM::BasicBlock)
  end

  def close(builder : LLVM::Builder) : Nil
    builder.position_at_end @scope
    builder.br @destination
  end
end

class ConditionalStatement < CloseStatement
  def initialize(@scope : LLVM::BasicBlock, @comp : LLVM::Value, @destination1 : LLVM::BasicBlock, @destination2 : LLVM::BasicBlock)
  end

  def close(builder : LLVM::Builder) : Nil
    builder.position_at_end @scope
    builder.cond @comp, @destination1, @destination2
  end
end
