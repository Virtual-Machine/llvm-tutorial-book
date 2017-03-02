alias ValueType = String | Int32 | Int64 | Float64 | Symbol | Bool | Nil | LLVM::Value | Array(LLVM::Value)
alias AST = Array(Node)
alias State = Hash(String, ValueType)

enum Context
  TopLevel
  Comment
  String
  Identifier
  Number
  Operator
  Def
end

enum TokenType
  Comment
  Keyword
  String
  Identifier
  Bool
  Symbol
  Float
  Int
  Operator
  Delimiter
  ParenOpen
  ParenClose
  Comma
  FuncDef
  FuncCall
  Type
end
