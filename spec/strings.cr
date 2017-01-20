require "spec"
require "../emerald/emerald"

describe "String processing" do
  system "./emeraldc test_inputs/input4.cr -e > test_outputs/output4"
  contents = File.read("test_outputs/output4")

  it "should resolve seven puts calls with desired string output" do
    contents.should eq "Hello from this file\nHello world!\nRepeated Repeated Repeated !\ntrue\nfalse\nfalse\ntrue\n"
  end
end
