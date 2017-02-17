require "spec"
require "../emerald/emerald"

describe "Integration" do
  system "./emeraldc test_inputs/full_integration.cr -e > test_outputs/full_integration"
  contents = File.read("test_outputs/full_integration")

  it "should resolve final output as expected" do
    contents.should eq "196.8\n"
  end
end
