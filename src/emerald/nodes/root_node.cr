class RootNode < Node
  def initialize
    super 1, 1
    @value = nil
    @parent = nil
  end

  def resolve_value(state : ProgramState) : Nil
    @resolved_value = @children[-1].resolved_value
  end
end
