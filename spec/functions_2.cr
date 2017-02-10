require "spec"
require "../emerald/emerald"

describe "Functions_2" do
  system "./emeraldc test_inputs/input10.cr -e > test_outputs/output10"
  contents = File.read("test_outputs/output10")

  it "should resolve final output as expected" do
    contents.should eq "1\n0\n11\n"
  end
end
