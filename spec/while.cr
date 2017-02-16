require "spec"
require "../emerald/emerald"

describe "While" do
  system "./emeraldc test_inputs/input11.cr -e > test_outputs/output11"
  contents = File.read("test_outputs/output11")

  it "should resolve final output as expected" do
    contents.should eq "1\n4\n3\n2\n1\n0\nWill print\n2\n4\n3\n2\n1\n0\nWill print\nOnce\n3\n4\n5\n"
  end
end
