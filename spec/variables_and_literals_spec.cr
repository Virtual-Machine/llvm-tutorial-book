require "spec"
require "../emerald/emerald"

describe "Generator" do
  system "./emeraldc test_inputs/variables_and_literals.cr -e > test_outputs/variables_and_literals"
  contents = File.read("test_outputs/variables_and_literals")

  it "should resolve final output as expected" do
    contents.should eq "8.3\n8.3\n8.3\n8.3\n8.3\n8.3\ntrue\nfalse\ntrue\nfalse\ntrue\nfalse\nfalse\ntrue\nfalse\ntrue\nfalse\ntrue\nfalse\nfalse\nfalse\nfalse\nfalse\nfalse\ntrue\ntrue\ntrue\ntrue\ntrue\ntrue\ntrue\nfalse\ntrue\nfalse\ntrue\nfalse\ntrue\ntrue\ntrue\ntrue\ntrue\nfalse\n"
  end
end
