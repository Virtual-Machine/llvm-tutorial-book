class Token
  getter typeT, value, line, column

  def initialize(@typeT : TokenType,
                 @value : ValueType,
                 @line : Int32,
                 @column : Int32)
  end
end
