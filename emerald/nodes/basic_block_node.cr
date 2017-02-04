class BasicBlockNode < Node
  property! block
  @block : LLVM::BasicBlock?

  def initialize(@line : Int32, @position : Int32)
    @value = nil
    @children = [] of Node
  end

  def pre_walk(state : ProgramState) : Nil
    block_name = "block#{state.blocks.size + 1}"
    self_block = state.active_function.basic_blocks.append block_name
    state.add_block block_name, self_block
    state.active_block = self_block
    @block = self_block
  end

  def resolve_value(state : ProgramState) : Nil
    @resolved_value = @children[-1].resolved_value
    if parent.is_a?(IfExpressionNode)
      scope = block
      @children.each do |child|
        if child.class == IfExpressionNode
          scope = child.as(IfExpressionNode).exit_block
        end
      end
      if !@children[-1].is_a?(ReturnNode)
        state.close_statements.push JumpStatement.new scope, parent.as(IfExpressionNode).exit_block
      end
    end
  end
end
