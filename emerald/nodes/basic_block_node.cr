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
    if parent.class == FunctionDeclarationNode
      counter = 0
      parent.as(FunctionDeclarationNode).params.each do |var, type_val|
        state.builder.position_at_end state.active_block
        if type_val == :Int32
          ptr = state.builder.alloca LLVM::Int32, var
          state.builder.store state.active_function.params[counter], ptr
          state.variable_pointers[state.active_function][var] = ptr
        elsif type_val == :Float64
          ptr = state.builder.alloca LLVM::Float, var
          state.builder.store state.active_function.params[counter], ptr
          state.variable_pointers[state.active_function][var] = ptr
        elsif type_val == :Bool
          ptr = state.builder.alloca LLVM::Int1, var
          state.builder.store state.active_function.params[counter], ptr
          state.variable_pointers[state.active_function][var] = ptr
        elsif type_val == :String
        else
          raise "Unable to alloca function declaration parameter #{var} of type #{type_val}"
        end
        counter += 1
      end
    end
  end

  def resolve_value(state : ProgramState) : Nil
    @resolved_value = @children[-1].resolved_value
    if parent.is_a?(IfExpressionNode) || parent.is_a?(WhileExpressionNode)
      scope = block
      @children.each do |child|
        if child.class == IfExpressionNode
          scope = child.as(IfExpressionNode).exit_block
        elsif child.class == WhileExpressionNode
          scope = child.as(WhileExpressionNode).exit_block
        end
      end
      if !@children[-1].is_a?(ReturnNode)
        if parent.is_a?(IfExpressionNode)
          state.close_statements.push JumpStatement.new scope, parent.as(IfExpressionNode).exit_block
        elsif parent.is_a?(WhileExpressionNode)
          state.close_statements.push JumpStatement.new scope, parent.as(WhileExpressionNode).cond_block
        end
      end
    end
  end
end
