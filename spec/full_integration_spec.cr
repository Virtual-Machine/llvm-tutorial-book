require "spec"
require "../emerald/emerald"

describe "Integration" do
  system "./emeraldc test_inputs/full_integration.cr -e > test_outputs/full_integration"
  contents = File.read("test_outputs/full_integration")

  it "should resolve final output as expected" do
    contents.should eq "196.8\n"
  end
end

describe "Integration_2" do
  system "./emeraldc test_inputs/full_integration_2.cr -e > test_outputs/full_integration_2"
  contents = File.read("test_outputs/full_integration_2")

  it "should resolve final output as expected" do
    contents.should eq "Hello\nHello\nHello\nHello\nYuge!\nNot so biggly\n6.7\n6.7\n6.7\n6.7\n6.7\n5.4\n"
  end
end

describe "Integration_3" do
  system "./emeraldc test_inputs/full_integration_3.cr -e > test_outputs/full_integration_3"
  contents = File.read("test_outputs/full_integration_3")

  it "should resolve final output as expected" do
    contents.should eq "Hellos\nHello\nHellos\nHellos\nGoodbye\nYuge!\ntrue\nNot so biggly\nfalse\n6.7\n6.7\n0\n"
  end
end
