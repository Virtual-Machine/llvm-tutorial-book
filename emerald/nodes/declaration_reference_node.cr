class DeclarationReferenceNode < Node
  def initialize(@value : String, @line : Int32, @position : Int32)
    @children = [] of Node
  end

  def resolve_value(state : ProgramState) : Nil
    @resolved_value = state.reference_variable state.active_function, @value.as(String), @line, @position
  end
end
