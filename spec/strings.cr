require "spec"
require "../emerald/emerald"

describe "String processing" do
    input = "
# puts string
puts \"Hello from this file\"

# string addition is concatenation
puts \"Hello\" + \" world!\"

# string multiplied by integer is repetition
puts \"Repeated \" * 3 + \"!\"

# strings can be equal or inqual to other strings
puts \"Hello\" == \"Hello\"
puts \"Hello\" != \"Hello\"
puts \"Hello\" == \"Hello1\"
puts \"Hello\" != \"Hello1\"
"

  program = EmeraldProgram.new input
  program.compile

  it "should resolve seven puts calls with desired string output" do
    program.state.instructions[0].class.should eq CallInstruction
    program.state.instructions[0].as(CallInstruction).params[0].should eq LLVM.string("Hello from this file")
    program.state.instructions[1].class.should eq CallInstruction
    program.state.instructions[1].as(CallInstruction).params[0].should eq LLVM.string("Hello world!")
    program.state.instructions[2].class.should eq CallInstruction
    program.state.instructions[2].as(CallInstruction).params[0].should eq LLVM.string("Repeated Repeated Repeated !")
    program.state.instructions[3].class.should eq CallInstruction
    program.state.instructions[3].as(CallInstruction).params[0].should eq LLVM.string("true")
    program.state.instructions[4].class.should eq CallInstruction
    program.state.instructions[4].as(CallInstruction).params[0].should eq LLVM.string("false")
    program.state.instructions[5].class.should eq CallInstruction
    program.state.instructions[5].as(CallInstruction).params[0].should eq LLVM.string("false")
    program.state.instructions[6].class.should eq CallInstruction
    program.state.instructions[6].as(CallInstruction).params[0].should eq LLVM.string("true")
  end

end
