class Token
  getter typeT, value, line, column

  def initialize(@typeT : TokenType,
                 @value : ValueType,
                 @line : Int32,
                 @column : Int32)
  end

  def inspect : String
    return "TOKEN:\n\tType: #{@typeT},\n\tValue: #{@value},\n\tLine: #{@line},\tColumn: #{@column}"
  end
end
