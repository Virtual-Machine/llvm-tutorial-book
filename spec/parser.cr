require "spec"
require "../emerald/emerald"

describe "Parser" do
	describe "parse" do

		input = "# I am a comment!
four = 2 + 2
puts four
puts 10 < 6
puts 11 != 10"

		program = EmeraldProgram.new input
		program.lex
		program.parse




		it "should parse AST as expected" do
			program.ast[0].class.should eq RootNode

			program.ast[0].children[0].class.should eq VariableDeclarationNode
			program.ast[0].children[0].value.should eq "four"
			program.ast[0].children[0].children[0].class.should eq ExpressionNode
			program.ast[0].children[0].children[0].children[0].class.should eq BinaryOperatorNode
			program.ast[0].children[0].children[0].children[0].value.should eq "+"
			program.ast[0].children[0].children[0].children[0].children[0].class.should eq IntegerLiteralNode
			program.ast[0].children[0].children[0].children[0].children[0].value.should eq 2
			program.ast[0].children[0].children[0].children[0].children[1].class.should eq IntegerLiteralNode
			program.ast[0].children[0].children[0].children[0].children[1].value.should eq 2

			program.ast[0].children[1].class.should eq CallExpressionNode
			program.ast[0].children[1].value.should eq "puts"
			program.ast[0].children[1].children[0].class.should eq ExpressionNode
			program.ast[0].children[1].children[0].children[0].class.should eq DeclarationReferenceNode
			program.ast[0].children[1].children[0].children[0].value.should eq "four"

			program.ast[0].children[2].class.should eq CallExpressionNode
			program.ast[0].children[2].value.should eq "puts"
			program.ast[0].children[2].children[0].class.should eq ExpressionNode
			program.ast[0].children[2].children[0].children[0].class.should eq BinaryOperatorNode
			program.ast[0].children[2].children[0].children[0].value.should eq "<"
			program.ast[0].children[2].children[0].children[0].children[0].class.should eq IntegerLiteralNode
			program.ast[0].children[2].children[0].children[0].children[0].value.should eq 10
			program.ast[0].children[2].children[0].children[0].children[1].class.should eq IntegerLiteralNode
			program.ast[0].children[2].children[0].children[0].children[1].value.should eq 6

			program.ast[0].children[3].class.should eq CallExpressionNode
			program.ast[0].children[3].value.should eq "puts"
			program.ast[0].children[3].children[0].class.should eq ExpressionNode
			program.ast[0].children[3].children[0].children[0].class.should eq BinaryOperatorNode
			program.ast[0].children[3].children[0].children[0].value.should eq "!="
			program.ast[0].children[3].children[0].children[0].children[0].class.should eq IntegerLiteralNode
			program.ast[0].children[3].children[0].children[0].children[0].value.should eq 11
			program.ast[0].children[3].children[0].children[0].children[1].class.should eq IntegerLiteralNode
			program.ast[0].children[3].children[0].children[0].children[1].value.should eq 10
		end
	end
end