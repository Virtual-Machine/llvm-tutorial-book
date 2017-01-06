class State
  def initialize
    @blocks = {} of String => LLVM::BasicBlock
    @ints = {} of Int32 => LLVM::Value
  end

  def add_block(name : String, block : LLVM::BasicBlock)
    @blocks[name] = block
  end

  def get_block(name : String)
    @blocks[name]
  end

  def add_integer(value : Int32)
    @ints[value] = LLVM.int(LLVM::Int32, value)
  end

  def get_integer(value : Int32)
    @ints[value]
  end
end
