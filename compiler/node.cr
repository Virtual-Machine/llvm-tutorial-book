class Node
  def initialize(@position : Int32, @line : Int32)
  end

  def inspect : String
    return "AST:\n\tLine: #{@line},\tColumn: #{@position}"
  end

  def terminal_node?
    false
  end
end
