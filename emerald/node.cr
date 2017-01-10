class Node
	getter value
	property parent, children, depth

	@value : ValueType
	@parent : Node?
	@depth = 0
  def initialize(@line : Int32, @position : Int32)
  	@children = [] of Node
  	@value = nil
  end

  def add_child(node : Node)
  	@children.push node
  	node.parent = self
  	node.depth = self.depth + 1
	end

	def promote(node : Node)
		insertion_point = get_binary_insertion_point node

		held_children = insertion_point.not_nil!.children
		insertion_point.not_nil!.children = [] of Node
		insertion_point.not_nil!.add_child node
		held_children.each do |child|
			node.add_child child
		end
	end

	def get_binary_insertion_point(node : Node) : Node
		active_parent = self.parent
		# Check if insertion point is a binary operator
		if active_parent.class == BinaryOperatorNode && node.precedence < active_parent.as(BinaryOperatorNode).precedence
			# If so keep checking parent of active insertion point
			while active_parent.not_nil!.parent.class == BinaryOperatorNode && 
				node.precedence < active_parent.not_nil!.parent.as(BinaryOperatorNode).precedence
				# Set insertion point to parent of insertion point
				active_parent = active_parent.not_nil!.parent
			end
		end
		# We know active parent is not nil because there should 
		# always be the root node at the top to kill the ast chain
		active_parent.not_nil!
	end
end


class RootNode < Node
	def initialize
		super 1, 1
		@value = nil
		@parent = nil
	end
end

class CallExpressionNode < Node
	def initialize(@value : ValueType, @line : Int32, @position : Int32)
		@children = [] of Node
	end
end

class VariableDeclarationNode < Node
	def initialize(@value : ValueType, @line : Int32, @position : Int32)
		@children = [] of Node
	end
end

class BinaryOperatorNode < Node
	def initialize(@value : ValueType, @line : Int32, @position : Int32)
		@children = [] of Node
	end

	def precedence : Int32
		case value
		when "+"
			5
		when "-"
			5
		when "*"
			10
		when "/"
			10
		else
			0
		end
	end
end

class IntegerLiteralNode < Node
	def initialize(@value : ValueType, @line : Int32, @position : Int32)
		@children = [] of Node
	end
end

class DeclarationReferenceNode < Node
	def initialize(@value : ValueType, @line : Int32, @position : Int32)
		@children = [] of Node
	end
end

class ExpressionNode < Node
	def initialize(@line : Int32, @position : Int32)
		@value = nil
		@children = [] of Node
	end
end