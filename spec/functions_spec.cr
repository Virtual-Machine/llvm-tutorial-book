require "spec"
require "../emerald/emerald"

describe "Functions" do
  system "./emeraldc test_inputs/functions.cr -e > test_outputs/functions"
  contents = File.read("test_outputs/functions")

  it "should resolve final output as expected" do
    contents.should eq "9\n2\nhello world\nhello hello hello hello hello hello hello hello hello \n"
  end
end
