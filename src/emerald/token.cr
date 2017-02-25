class Token
  getter typeT, value, line, column

  def initialize(@typeT : TokenType,
                 @value : ValueType,
                 @line : Int32,
                 @column : Int32)
  end

  def to_s : String
    "<#{@line}:#{@column}>\t- #{self.typeT}   \t- #{self.value}"
  end
end
