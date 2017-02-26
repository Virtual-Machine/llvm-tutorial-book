require "spec"
require "../emerald/emerald"

describe "If Statements" do
  describe "integration tests with if statements and puts calls" do
    system "./emeraldc test_inputs/if_statements_1.cr -e > test_outputs/if_statements_1"
    contents = File.read("test_outputs/if_statements_1")
    it "should evaluate if_statements_1 as expected" do
      contents == "1\n"
    end

    system "./emeraldc test_inputs/if_statements_2.cr -e > test_outputs/if_statements_2"
    contents = File.read("test_outputs/if_statements_2")
    it "should evaluate if_statements_2 as expected" do
      contents == "starting\nok3\n4\nok4\ndone\n"
    end
  end
end
