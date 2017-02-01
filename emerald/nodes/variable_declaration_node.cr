class VariableDeclarationNode < Node
  def initialize(@value : String, @line : Int32, @position : Int32)
    @children = [] of Node
  end

  def resolve_value(state : ProgramState) : Nil
    @resolved_value = @children[0].resolved_value
    state.add_variable state.active_function, @value.as(String), @resolved_value
    if @resolved_value.is_a?(String)
      state.define_or_find_global @resolved_value.as(String)
    end
  end
end
