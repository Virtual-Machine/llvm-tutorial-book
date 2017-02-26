require "spec"
require "../emerald/emerald"

describe "String processing" do
  system "./emeraldc test_inputs/strings.cr -e > test_outputs/strings"
  contents = File.read("test_outputs/strings")

  it "should resolve seven puts calls with desired string output" do
    contents.should eq "Hello from this file\nHello world!\nRepeated Repeated Repeated !\ntrue\nfalse\nfalse\ntrue\n"
  end
end
