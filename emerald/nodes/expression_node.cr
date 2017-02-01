class ExpressionNode < Node
  getter parens

  def initialize(@parens : Bool, @line : Int32, @position : Int32)
    @value = nil
    @children = [] of Node
  end

  def resolve_value(state : ProgramState) : Nil
    @resolved_value = @children[0].resolved_value
  end
end
