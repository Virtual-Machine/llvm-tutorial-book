require "spec"
require "../emerald/emerald"

# Note that these examples create program examples with:
#      EmeraldProgram.new_from_input input_code, true
# The true param forces program to re-raise exception instead of printing and exiting to allow tests to work as expected.

describe "Errors" do
  describe "Emerald error handling" do
    it "should catch bad combinations of tokens 1" do
      expect_raises EmeraldTokenVerificationException do
        program = EmeraldProgram.new_from_input "puts ( * 2)", true
        program.compile
      end
    end

    it "should catch bad combinations of tokens 2" do
      expect_raises EmeraldTokenVerificationException do
        program = EmeraldProgram.new_from_input "puts (2 *)", true
        program.compile
      end
    end

    it "should catch bad combinations of tokens 3" do
      expect_raises EmeraldTokenVerificationException do
        program = EmeraldProgram.new_from_input "puts 2 * * 2", true
        program.compile
      end
    end

    it "should catch bad combinations of tokens 4" do
      expect_raises EmeraldTokenVerificationException do
        program = EmeraldProgram.new_from_input "puts 2 ()", true
        program.compile
      end
    end

    it "should catch bad combinations of tokens 5" do
      expect_raises EmeraldTokenVerificationException do
        program = EmeraldProgram.new_from_input "puts () 2", true
        program.compile
      end
    end

    it "should catch bad combinations of tokens 6" do
      expect_raises EmeraldTokenVerificationException do
        program = EmeraldProgram.new_from_input "puts 2 \"Int\"", true
        program.compile
      end
    end

    it "should catch value resolution errors for undefined operators on known type combinations" do
      expect_raises EmeraldValueResolutionException do
        program = EmeraldProgram.new_from_input "puts 1 += 1", true
        program.compile
      end
    end

    it "should catch value resolution errors for undefined type combinations" do
      expect_raises EmeraldValueResolutionException do
        program = EmeraldProgram.new_from_input "puts true + 1", true
        program.compile
      end
    end

    it "should catch parsing exception for undefined top level tokens" do
      expect_raises EmeraldParsingException do
        program = EmeraldProgram.new_from_input "+ 2", true
        program.compile
      end
    end

    it "should catch parsing exception for closing unopened parenthesis" do
      expect_raises EmeraldParsingException do
        program = EmeraldProgram.new_from_input "2 + 2)", true
        program.compile
      end
    end

    it "should catch parsing exception for unclosed parenthesis" do
      expect_raises EmeraldParsingException do
        program = EmeraldProgram.new_from_input "(2 + 2", true
        program.compile
      end
    end

    it "should catch variable reference exception for undefined variables" do
      expect_raises EmeraldVariableReferenceException do
        program = EmeraldProgram.new_from_input "puts hello", true
        program.compile
      end
    end

    it "should catch invalid function declarations - no parameter type" do
      expect_raises EmeraldParsingException do
        program = EmeraldProgram.new_from_input "def add_up(x) Int32\nreturn 0 + x\nend", true
        program.compile
      end
    end

    it "should catch invalid function declarations - no parameter type multiple" do
      expect_raises EmeraldParsingException do
        program = EmeraldProgram.new_from_input "def add_up(x, y Int32) Int32\nreturn 0\nend", true
        program.compile
      end
    end

    it "should catch invalid function declarations - no return type" do
      expect_raises EmeraldParsingException do
        program = EmeraldProgram.new_from_input "def add_up(x Int32)\nreturn 0 + x\nend", true
        program.compile
      end
    end

    # Currently unable to test for EmeraldInstructionException
    # Not sure if there is possible input to generate error as of yet.
  end
end
