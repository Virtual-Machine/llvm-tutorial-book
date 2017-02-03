require "spec"
require "../emerald/emerald"

describe "Generator" do
  system "./emeraldc test_inputs/input5.cr -e > test_outputs/output5"
  contents = File.read("test_outputs/output5")

  it "should resolve final output as -221" do
    contents.should eq "-221\n"
  end

  system "./emeraldc test_inputs/input6.cr -e > test_outputs/output6"
  contents = File.read("test_outputs/output6")

  it "should resolve final output as -1138, false" do
    contents.should eq "-1138\nfalse\n"
  end

  describe "value resolution_3" do
    input = "
puts (4 +
3
*
2)
"

    program3 = EmeraldProgram.new_from_input input
    program3.compile

    first_expression = program3.ast[0].children[0]

    it "resolves multi-line expressions wrapped in parenthesis" do
      first_expression.resolved_value.should eq 10
    end
  end
end
