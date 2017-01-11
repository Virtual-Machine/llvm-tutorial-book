require "spec"
require "../emerald/emerald"

describe "Parser" do
  describe "parse" do
    input = "
four = (2 + 2) * 3 + 2 * (5 + (6 * 7))
puts four - 3 * (four + 3)"

    program = EmeraldProgram.new input
    program.lex
    program.parse

    root = program.ast[0]
    four_decl = root.children[0]

    addition_1 = four_decl.children[0].children[0]
    multiply_1 = addition_1.children[0]
    addition_2 = multiply_1.children[0].children[0]
    multiply_2 = addition_1.children[1]
    addition_3 = multiply_2.children[1].children[0]
    multiply_3 = addition_3.children[1].children[0]

    int_2_1 = addition_2.children[0]
    int_2_2 = addition_2.children[1]
    int_2_3 = multiply_2.children[0]
    int_3_1 = multiply_1.children[1]
    int_5_1 = addition_3.children[0]
    int_6_1 = multiply_3.children[0]
    int_7_1 = multiply_3.children[1]
    it "parses first command as variable declaration receiving complex equation" do
      four_decl.class.should eq VariableDeclarationNode
      four_decl.value.should eq "four"
      addition_1.class.should eq BinaryOperatorNode
      addition_1.value.should eq "+"
      addition_2.class.should eq BinaryOperatorNode
      addition_2.value.should eq "+"
      int_2_1.class.should eq IntegerLiteralNode
      int_2_1.value.should eq 2
      int_2_2.class.should eq IntegerLiteralNode
      int_2_2.value.should eq 2
      addition_3.class.should eq BinaryOperatorNode
      addition_3.value.should eq "+"
      int_5_1.class.should eq IntegerLiteralNode
      int_5_1.value.should eq 5
      multiply_1.class.should eq BinaryOperatorNode
      multiply_1.value.should eq "*"
      int_3_1.class.should eq IntegerLiteralNode
      int_3_1.value.should eq 3
      multiply_2.class.should eq BinaryOperatorNode
      multiply_2.value.should eq "*"
      int_2_3.class.should eq IntegerLiteralNode
      int_2_3.value.should eq 2
      multiply_3.class.should eq BinaryOperatorNode
      multiply_3.value.should eq "*"
      int_6_1.class.should eq IntegerLiteralNode
      int_6_1.value.should eq 6
      int_7_1.class.should eq IntegerLiteralNode
      int_7_1.value.should eq 7
    end

    call_expr = root.children[1]
    subtract_1 = call_expr.children[0].children[0]
    var_decl_1 = subtract_1.children[0]
    multiply_4 = subtract_1.children[1]
    int_3_2 = multiply_4.children[0]
    addition_4 = multiply_4.children[1].children[0]
    var_decl_2 = addition_4.children[0]
    int_3_3 = addition_4.children[1]
    it "parses second command as call expression resolving two declaration references" do
      call_expr.class.should eq CallExpressionNode
      call_expr.value.should eq "puts"
      subtract_1.class.should eq BinaryOperatorNode
      subtract_1.value.should eq "-"
      var_decl_1.class.should eq DeclarationReferenceNode
      var_decl_1.value.should eq "four"
      multiply_4.class.should eq BinaryOperatorNode
      multiply_4.value.should eq "*"
      int_3_2.class.should eq IntegerLiteralNode
      int_3_2.value.should eq 3
      addition_4.class.should eq BinaryOperatorNode
      addition_4.value.should eq "+"
      var_decl_2.class.should eq DeclarationReferenceNode
      var_decl_2.value.should eq "four"
      int_3_3.class.should eq IntegerLiteralNode
      int_3_3.value.should eq 3
    end
  end
end
