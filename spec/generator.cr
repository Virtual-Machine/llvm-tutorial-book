require "spec"
require "../emerald/emerald"

expected = %[; ModuleID = 'Emerald'
source_filename = \"Emerald\"

@puts_pointer = private unnamed_addr constant [2 x i8] c\"4\\00\"
@puts_pointer.1 = private unnamed_addr constant [6 x i8] c\"false\\00\"
@puts_pointer.2 = private unnamed_addr constant [5 x i8] c\"true\\00\"

define i32 @main() {
main_body:
  %return_value_call = call i32 @puts(i8* getelementptr inbounds ([2 x i8], [2 x i8]* @puts_pointer, i32 0, i32 0))
  %return_value_call1 = call i32 @puts(i8* getelementptr inbounds ([6 x i8], [6 x i8]* @puts_pointer.1, i32 0, i32 0))
  %return_value_call2 = call i32 @puts(i8* getelementptr inbounds ([5 x i8], [5 x i8]* @puts_pointer.2, i32 0, i32 0))
  ret i32 0
}

declare i32 @puts(i8*)
]

describe "Generator" do
  describe "generate" do
    input = "# I am a comment!
four = 2 + 2
puts four
puts 10 < 6
puts 11 != 10"

    program = EmeraldProgram.new input
    program.compile

    it "should output exact LLVM IR for basic example input" do
      program.mod.to_s.should eq expected
    end
  end
end
