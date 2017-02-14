class ExpressionNode < Node
  getter parens

  def initialize(@parens : Bool, @line : Int32, @position : Int32)
    @value = nil
    @children = [] of Node
  end

  def resolve_value(state : ProgramState) : Nil
    if @children.size == 1
      @resolved_value = @children[0].resolved_value
    else
      params = [] of LLVM::Value
      @children.each do |child|
        cur_child_value = child.resolved_value
        if cur_child_value.is_a?(Array(LLVM::Value))
          cur_child_value.each do |value|
            params.push crystal_to_llvm state, value
          end
        else
          params.push crystal_to_llvm state, cur_child_value
        end
      end
      @resolved_value = params
    end
  end
end
