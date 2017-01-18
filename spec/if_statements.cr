require "spec"
require "../emerald/emerald"

describe "If Statements" do
  describe "integration tests with if statements and puts calls" do
    system "./emeraldc test_inputs/input1.cr -e > test_outputs/output1"
    contents = File.read("test_outputs/output1")
    it "should evaluate input1 as expected" do
      contents == "1\n"
    end

    system "./emeraldc test_inputs/input2.cr -e > test_outputs/output2"
    contents = File.read("test_outputs/output2")
    it "should evaluate input2 as expected" do
      contents == "starting\nok3\n4\nok4\ndone\n"
    end
  end
end
