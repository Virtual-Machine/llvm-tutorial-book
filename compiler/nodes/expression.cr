require "../node"

class ExpressionNode < Node
  getter expression

  def initialize(@line : Int32, @position : Int32)
    super
    @expression = ""
  end

  def inspect : String
    return "Expression Node:\n\tExpression: #{@expression}\n\tLine: #{@line},\tColumn: #{@position}"
  end
end
