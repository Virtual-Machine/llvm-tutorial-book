alias ValueType = String | Int32 | Float64 | Symbol | Nil
alias AST = Array(Node)

enum Context
  TopLevel
  Comment
  String
  Identifier
  Number
  Operator
end

enum TokenType
  Comment
  Keyword
  String
  Identifier
  Float
  Int
  Operator
  Delimiter
  ParenOpen
  ParenClose
end
