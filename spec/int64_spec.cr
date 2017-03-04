require "spec"
require "../emerald/emerald"

describe "While" do
  system "./emeraldc test_inputs/int64.cr -e > test_outputs/int64"
  contents = File.read("test_outputs/int64")

  it "should resolve final output as expected" do
    contents.should eq "9223372036854775807\n9223372036854775806\n9223372\n"
  end
end
