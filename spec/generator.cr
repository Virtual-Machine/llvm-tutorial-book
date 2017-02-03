require "spec"
require "../emerald/emerald"

expected = %[; ModuleID = 'Emerald'
source_filename = \"Emerald\"

@0 = private unnamed_addr constant [6 x i8] c\"false\\00\"
@1 = private unnamed_addr constant [5 x i8] c\"true\\00\"

define i32 @main() {
main_body:
  %four = alloca i32
  store i32 4, i32* %four
  %0 = load i32, i32* %four
  %puts = call i32 @\"puts:int\"(i32 %0)
  %puts1 = call i32 @\"puts:str\"(i8* getelementptr inbounds ([6 x i8], [6 x i8]* @0, i32 0, i32 0))
  %puts2 = call i32 @\"puts:str\"(i8* getelementptr inbounds ([5 x i8], [5 x i8]* @1, i32 0, i32 0))
  ret i32 0
}
]

describe "Generator" do
  describe "generate" do
    input = "# I am a comment!
four = 2 + 2
puts four
puts 10 < 6
puts 11 != 10"

    program = EmeraldProgram.new_from_input input
    program.compile

    it "should output exact LLVM IR for basic example input" do
      program.mod.to_s[0, 522].should eq expected
    end
  end
end
