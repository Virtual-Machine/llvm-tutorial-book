class IfExpressionNode < Node
  property! exit_block, if_block, else_block, entry_block 
  getter uses_exit
  @entry_block : LLVM::BasicBlock?
  @exit_block : LLVM::BasicBlock?
  @if_block : LLVM::BasicBlock?
  @else_block : LLVM::BasicBlock?

  def initialize(@line : Int32, @position : Int32)
    @value = nil
    @children = [] of Node
    @uses_exit = true
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
    # If/else where both if and else blocks end in return nodes...
    if @children[2]? && @children[1].children[-1].is_a?(ReturnNode) && @children[2].children[-1].is_a?(ReturnNode)
      state.builder.position_at_end exit_block
      # ...then the exit block is unreachable
      state.builder.unreachable
      @uses_exit = false
    end
    @if_block = @children[1].as(BasicBlockNode).block
    if @children[2]?
      @else_block = @children[2].as(BasicBlockNode).block
    end

    comp_val = @children[0].resolved_value
    if comp_val == true
      comp_val = state.int1.const_int(1)
    elsif comp_val == false
      comp_val = state.int1.const_int(0)
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
