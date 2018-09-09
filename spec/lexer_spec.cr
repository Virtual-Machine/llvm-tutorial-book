require "spec"
require "../emerald/emerald"

describe "Lexer" do
  describe "lex" do
    input = "# I am a comment!
four = 2 + 2
puts four
puts 10 < 6
puts 11 != 10"

    program = EmeraldProgram.new_from_input input
    program.lex

    test_data = { 0 => [TokenType::Comment, "I am a comment!", 1, 1],
                  1 => [TokenType::Delimiter, :endl, 1, 18],
                  2 => [TokenType::Identifier, "four", 2, 1],
                  3 => [TokenType::Operator, "=", 2, 6],
                  4 => [TokenType::Int, 2, 2, 8],
                  5 => [TokenType::Operator, "+", 2, 10],
                  6 => [TokenType::Int, 2, 2, 12],
                  7 => [TokenType::Delimiter, :endl, 2, 13],
                  8 => [TokenType::Keyword, :puts, 3, 1],
                  9 => [TokenType::Identifier, "four", 3, 6],
                 10 => [TokenType::Delimiter, :endl, 3, 10],
                 11 => [TokenType::Keyword, :puts, 4, 1],
                 12 => [TokenType::Int, 10, 4, 6],
                 13 => [TokenType::Operator, "<", 4, 9],
                 14 => [TokenType::Int, 6, 4, 11],
                 15 => [TokenType::Delimiter, :endl, 4, 12],
                 16 => [TokenType::Keyword, :puts, 5, 1],
                 17 => [TokenType::Int, 11, 5, 6],
                 18 => [TokenType::Operator, "!=", 5, 9],
                 19 => [TokenType::Int, 10, 5, 12],
                 20 => [TokenType::Delimiter, :endf, 5, 14]}

    test_data.each do |index, array|
      it "should build expected token array #{index}" do
        program.token_array[index].typeT.should eq array[0]
        program.token_array[index].value.should eq array[1]
        program.token_array[index].line.should eq array[2]
        program.token_array[index].column.should eq array[3]
      end
    end
  end
end
