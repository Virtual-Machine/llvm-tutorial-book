class WhenExpressionNode < Node
  property! exit_block, cond_block, body_block, entry_block
  @entry_block : LLVM::BasicBlock?
  @exit_block : LLVM::BasicBlock?
  @cond_block : LLVM::BasicBlock?
  @body_block : LLVM::BasicBlock?

  def initialize(@line : Int32, @position : Int32)
    @value = nil
    @children = [] of Node
  end

  def pre_walk(state : ProgramState) : Nil
    block_name = "eblock#{state.blocks.size + 1}"
    exit_block = state.mod.functions[state.active_function_name].basic_blocks.append block_name
    state.add_block block_name, exit_block
    cond_name = "cond#{state.blocks.size + 1}"
    cond_block = state.mod.functions[state.active_function_name].basic_blocks.append cond_name
    state.add_block cond_name, cond_block

    @entry_block = state.active_block
    state.close_statements.push JumpStatement.new entry_block, cond_block
    @exit_block = exit_block
    @cond_block = cond_block
    state.active_block = cond_block
  end

  def resolve_value(state : ProgramState) : Nil
    state.active_block = @exit_block

    @body_block = @children[1].as(BasicBlockNode).block

    @resolved_value = @children[1].resolved_value

    comp_val = @children[0].resolved_value
    if comp_val == true
      comp_val = LLVM.int(LLVM::Int1, 1)
    elsif comp_val == false
      comp_val = LLVM.int(LLVM::Int1, 0)
    else
      comp_val = comp_val.as(LLVM::Value)
    end

    state.close_statements.push ConditionalStatement.new cond_block, comp_val, body_block, exit_block
  end
end
