require "spec"
require "../emerald/emerald"

describe "Float processing" do
    input = "
puts 3.4 + 2.5

puts 3.4 + 2.5 * 2

puts 7.5 < 9.5

puts 2.5 + 2 - 1.5 - 1

puts 5 / 2 * 4 - 3 + 4

puts 7.5 < 8
"

  program = EmeraldProgram.new input
  program.compile

  it "should resolve six puts calls with desired output" do
    program.state.instructions[0].class.should eq CallInstruction
    program.state.instructions[0].as(CallInstruction).params[0].should eq LLVM.string("5.9")
    program.state.instructions[1].class.should eq CallInstruction
    program.state.instructions[1].as(CallInstruction).params[0].should eq LLVM.string("8.4")
    program.state.instructions[2].class.should eq CallInstruction
    program.state.instructions[2].as(CallInstruction).params[0].should eq LLVM.string("true")
    program.state.instructions[3].class.should eq CallInstruction
    program.state.instructions[3].as(CallInstruction).params[0].should eq LLVM.string("2.0")
    program.state.instructions[4].class.should eq CallInstruction
    program.state.instructions[4].as(CallInstruction).params[0].should eq LLVM.string("9")
    program.state.instructions[5].class.should eq CallInstruction
    program.state.instructions[5].as(CallInstruction).params[0].should eq LLVM.string("true")
  end
end
