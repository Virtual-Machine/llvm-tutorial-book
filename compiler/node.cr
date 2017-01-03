class Node
  def initialize(@line : Int32, @position : Int32)
  end

  def inspect : String
    return "AST:\n\tLine: #{@line},\tColumn: #{@position}"
  end
end
