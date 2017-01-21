require "spec"
require "../emerald/emerald"

describe "Generator" do
  system "./emeraldc test_inputs/input7.cr -e > test_outputs/output7"
  contents = File.read("test_outputs/output7")

  it "should resolve final output as expected" do
    contents.should eq "8.300000\n8.300000\n8.300000\n8.300000\n8.300000\n8.300000\ntrue\nfalse\ntrue\nfalse\ntrue\nfalse\nfalse\ntrue\nfalse\ntrue\nfalse\ntrue\nfalse\nfalse\nfalse\nfalse\nfalse\nfalse\ntrue\ntrue\ntrue\ntrue\ntrue\ntrue\ntrue\nfalse\ntrue\nfalse\ntrue\nfalse\ntrue\ntrue\ntrue\ntrue\ntrue\nfalse\n"
  end
end
