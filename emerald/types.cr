alias ValueType = String | Int32 | Symbol | Nil
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
  Int
  Operator
  Delimiter
end
