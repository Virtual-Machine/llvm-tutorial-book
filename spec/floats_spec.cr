require "spec"
require "../emerald/emerald"

describe "Float processing" do
  system "./emeraldc test_inputs/floats.cr -e > test_outputs/floats"
  contents = File.read("test_outputs/floats")

  it "should evaluate floats as expected" do
    contents.should eq "5.9\n8.4\ntrue\n2.0\n9\ntrue\ntrue\nfalse\n"
  end
end
