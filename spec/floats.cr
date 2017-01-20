require "spec"
require "../emerald/emerald"

describe "Float processing" do
  system "./emeraldc test_inputs/input3.cr -e > test_outputs/output3"
  contents = File.read("test_outputs/output3")

  it "should evaluate input3 as expected" do
    contents.should eq "5.9\n8.4\ntrue\n2.0\n9\ntrue\ntrue\nfalse\n"
  end
end
