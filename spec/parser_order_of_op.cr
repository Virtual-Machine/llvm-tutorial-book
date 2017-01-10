require "spec"
require "../emerald/emerald"

describe "Parser_2" do
	describe "parse_order_of_operations" do
		input = "4 * 3 + 2"

		program2 = EmeraldProgram.new input
		program2.lex
		program2.parse

		it "should parse number expressions at root level" do
			program2.ast[0].children[0].class.should eq ExpressionNode
			program2.ast[0].children[0].children[0].class.should eq BinaryOperatorNode
			program2.ast[0].children[0].children[0].value.should eq "+"
			program2.ast[0].children[0].children[0].children[0].class.should eq BinaryOperatorNode
			program2.ast[0].children[0].children[0].children[0].value.should eq "*"
			program2.ast[0].children[0].children[0].children[0].children[0].class.should eq IntegerLiteralNode
			program2.ast[0].children[0].children[0].children[0].children[0].value.should eq 4
			program2.ast[0].children[0].children[0].children[0].children[1].class.should eq IntegerLiteralNode
			program2.ast[0].children[0].children[0].children[0].children[1].value.should eq 3
			program2.ast[0].children[0].children[0].children[1].class.should eq IntegerLiteralNode
			program2.ast[0].children[0].children[0].children[1].value.should eq 2
		end

		input = "4 * ((3 + 2) + 1) + 5"

		program3 = EmeraldProgram.new input
		program3.lex
		program3.parse

		it "should handle parenthesis as sub expressions" do
			program3.ast[0].children[0].class.should eq ExpressionNode
			program3.ast[0].children[0].children[0].class.should eq BinaryOperatorNode
			program3.ast[0].children[0].children[0].value.should eq "+"
			program3.ast[0].children[0].children[0].children[0].class.should eq BinaryOperatorNode
			program3.ast[0].children[0].children[0].children[0].value.should eq "*"
			program3.ast[0].children[0].children[0].children[0].children[0].class.should eq IntegerLiteralNode
			program3.ast[0].children[0].children[0].children[0].children[0].value.should eq 4
			program3.ast[0].children[0].children[0].children[0].children[1].class.should eq ExpressionNode
			program3.ast[0].children[0].children[0].children[0].children[1].children[0].class.should eq BinaryOperatorNode
			program3.ast[0].children[0].children[0].children[0].children[1].children[0].value.should eq "+"
			program3.ast[0].children[0].children[0].children[0].children[1].children[0].children[0].class.should eq ExpressionNode
			program3.ast[0].children[0].children[0].children[0].children[1].children[0].children[0].children[0].class.should eq BinaryOperatorNode
			program3.ast[0].children[0].children[0].children[0].children[1].children[0].children[0].children[0].value.should eq "+"
			program3.ast[0].children[0].children[0].children[0].children[1].children[0].children[0].children[0].children[0].class.should eq IntegerLiteralNode
			program3.ast[0].children[0].children[0].children[0].children[1].children[0].children[0].children[0].children[0].value.should eq 3
			program3.ast[0].children[0].children[0].children[0].children[1].children[0].children[0].children[0].children[1].class.should eq IntegerLiteralNode
			program3.ast[0].children[0].children[0].children[0].children[1].children[0].children[0].children[0].children[1].value.should eq 2
			program3.ast[0].children[0].children[0].children[0].children[1].children[0].children[1].class.should eq IntegerLiteralNode
			program3.ast[0].children[0].children[0].children[0].children[1].children[0].children[1].value.should eq 1
			program3.ast[0].children[0].children[0].children[1].class.should eq IntegerLiteralNode
			program3.ast[0].children[0].children[0].children[1].value.should eq 5
		end
	end
end