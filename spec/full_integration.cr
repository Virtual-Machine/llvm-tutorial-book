require "spec"
require "../emerald/emerald"

describe "Generator" do
  system "./emeraldc test_inputs/input8.cr -e > test_outputs/output8"
  contents = File.read("test_outputs/output8")

  it "should resolve final output as expected" do
    contents.should eq "196.8\n"
  end
end
