require "../node"

class StringLiteralNode < Node
  def initialize(@value : String)
    super
  end
end
