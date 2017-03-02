class IntegerLiteralNode < Node
  def initialize(@value : Int32, @line : Int32, @position : Int32)
    @children = [] of Node
  end

  def resolve_value(state : ProgramState) : Nil
    @resolved_value = value
  end
end

class Integer64LiteralNode < Node
  def initialize(@value : Int64, @line : Int32, @position : Int32)
    @children = [] of Node
  end

  def resolve_value(state : ProgramState) : Nil
    @resolved_value = value
  end
end

class StringLiteralNode < Node
  def initialize(@value : String, @line : Int32, @position : Int32)
    @children = [] of Node
  end

  def resolve_value(state : ProgramState) : Nil
    @resolved_value = value
  end
end

class FloatLiteralNode < Node
  def initialize(@value : Float64, @line : Int32, @position : Int32)
    @children = [] of Node
  end

  def resolve_value(state : ProgramState) : Nil
    @resolved_value = value
  end
end

class BooleanLiteralNode < Node
  def initialize(@value : Bool, @line : Int32, @position : Int32)
    @children = [] of Node
  end

  def resolve_value(state : ProgramState) : Nil
    @resolved_value = value
  end
end
