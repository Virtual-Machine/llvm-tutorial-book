class IfExpressionNode < Node
  property! exit_block, if_block, else_block, entry_block
  @entry_block : LLVM::BasicBlock?
  @exit_block : LLVM::BasicBlock?
  @if_block : LLVM::BasicBlock?
  @else_block : LLVM::BasicBlock?

  def initialize(@line : Int32, @position : Int32)
    @value = nil
    @children = [] of Node
  end

  def pre_walk(state : ProgramState) : Nil
    block_name = "eblock#{state.blocks.size + 1}"
    exit_block = state.mod.functions[state.active_function_name].basic_blocks.append block_name
    state.add_block block_name, exit_block
    @entry_block = state.active_block
    @exit_block = exit_block
  end

  def resolve_value(state : ProgramState) : Nil
    state.active_block = @exit_block
    @if_block = @children[1].as(BasicBlockNode).block
    if @children[2]?
      @else_block = @children[2].as(BasicBlockNode).block
    end

    if @children[0].resolved_value == true
      @resolved_value = @children[1].resolved_value
    else
      if @children[2]?
        @resolved_value = @children[2].resolved_value
      end
    end

    comp_val = @children[0].resolved_value
    if comp_val == true
      comp_val = LLVM.int(LLVM::Int1, 1)
    elsif comp_val == false
      comp_val = LLVM.int(LLVM::Int1, 0)
    else
      comp_val = comp_val.as(LLVM::Value)
    end

    if @children[2]?
      state.close_statements.push ConditionalStatement.new entry_block, comp_val, if_block, else_block
    else
      state.close_statements.push ConditionalStatement.new entry_block, comp_val, if_block, exit_block
    end
  end
end
