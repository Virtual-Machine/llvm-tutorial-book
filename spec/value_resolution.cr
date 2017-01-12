require "spec"
require "../emerald/emerald"

describe "Generator" do
  describe "value resolution" do
    input = "
var_106 = (2 + 2) * 3 + 2 * (5 + (6 * 7))
puts var_106 - 3 * (var_106 + 3)"

    program = EmeraldProgram.new input
    program.compile

    first_expression = program.ast[0].children[0]
    second_expression = program.ast[0].children[1]

    it "resolves value of first expression as var_106 = 106" do
      first_expression.class.should eq VariableDeclarationNode
      first_expression.value.should eq "var_106"
      first_expression.resolved_value.should eq 106
    end

    it "resolves value of second expression as puts -221" do
      second_expression.class.should eq CallExpressionNode
      second_expression.value.should eq "puts"
      second_expression.resolved_value.should eq -221
    end
  end

  describe "value resolution_2" do
    input = "
var_neg_1138 = (2 + 2) * (3 + 2 * (2 - 5)) + 2 - 8 * 3 * (5 + (6 * 7))
puts var_neg_1138 + 8 * 2 < var_neg_1138 - 8 * 2
"

    program2 = EmeraldProgram.new input
    program2.compile

    first_expression = program2.ast[0].children[0]
    second_expression = program2.ast[0].children[1]

    it "resolves value of first expression as -1138" do
      first_expression.resolved_value.should eq -1138
    end

    it "resolves value of second expression as false" do
      second_expression.resolved_value.should eq false
    end
  end
end
