require "../node"

class ExpressionsNode < Node
  getter nodes

  def initialize(@line : Int32, @position : Int32)
    super
    @nodes = [] of Node
  end

  def inspect : String
    return "Expressions Node:\n\tNodes: #{@nodes}\n\tLine: #{@line},\tColumn: #{@position}"
  end
end
