require "spec"
require "../emerald/emerald"

describe "Parser" do
  describe "parse" do
    input = "
four = (2 + 2) * 3 + 2 * (5 + (6 * 7))
puts four - 3 * (four + 3)"

    program = EmeraldProgram.new input
    program.compile

    first_expression = program.ast[0].children[0]
    second_expression = program.ast[0].children[1]

    it "resolves value of first expression as four = 106" do
      first_expression.class.should eq VariableDeclarationNode
      first_expression.value.should eq "four"
      first_expression.resolved_value.should eq 106
    end

    it "resolves value of second expression as puts -221" do
      second_expression.class.should eq CallExpressionNode
      second_expression.value.should eq "puts"
      second_expression.resolved_value.should eq -221
    end
  end
end
