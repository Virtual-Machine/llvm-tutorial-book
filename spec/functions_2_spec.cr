require "spec"
require "../emerald/emerald"

describe "Functions_2" do
  system "./emeraldc test_inputs/functions_2.cr -e > test_outputs/functions_2"
  contents = File.read("test_outputs/functions_2")

  it "should resolve final output as expected" do
    contents.should eq "1\n0\n11\n1\n6\n11\n12\n"
  end
end
