require "./nodes"

class AST
  getter nodes

  def AST.demo
    ast = Node.new
    main = FunctionDeclarationNode.new "main", "int ()"
    main_body = CompoundStatementNode.new
    declare1 = DeclarationStatementNode.new
    number_decl = VariableDeclarationNode.new "number", "int"
    declare2 = DeclarationStatementNode.new
    two_decl = VariableDeclarationNode.new "two", "int"
    two_literal = IntegerLiteralNode.new 2
    three_decl = VariableDeclarationNode.new "three", "int"
    three_literal = IntegerLiteralNode.new 3
    four_decl = VariableDeclarationNode.new "four", "int"
    four_literal = IntegerLiteralNode.new 4
    if_statement = IfStatementNode.new
    compare = BinaryOperatorNode.new "<"
    add = BinaryOperatorNode.new "+"
    implicit_cast1 = ImplicitCastExpressionNode.new "int"
    variable_ref1 = DeclarationReferenceExpressionNode.new "two"
    multiply = BinaryOperatorNode.new "*"
    implicit_cast2 = ImplicitCastExpressionNode.new "int"
    variable_ref2 = DeclarationReferenceExpressionNode.new "three"
    implicit_cast3 = ImplicitCastExpressionNode.new "int"
    variable_ref3 = DeclarationReferenceExpressionNode.new "four"
    implicit_cast4 = ImplicitCastExpressionNode.new "int"
    variable_ref4 = DeclarationReferenceExpressionNode.new "three"
    if_body = CompoundStatementNode.new
    set_value1 = BinaryOperatorNode.new "="
    variable_ref5 = DeclarationReferenceExpressionNode.new "number"
    implicit_cast6 = ImplicitCastExpressionNode.new "int"
    variable_ref6 = DeclarationReferenceExpressionNode.new "two"
    else_body = CompoundStatementNode.new
    set_value2 = BinaryOperatorNode.new "="
    variable_ref7 = DeclarationReferenceExpressionNode.new "number"
    five_literal = IntegerLiteralNode.new 5
    return_stmt = ReturnStatementNode.new
    implicit_cast8 = ImplicitCastExpressionNode.new "int"
    variable_ref8 = DeclarationReferenceExpressionNode.new "number"

    ast.add_child main
    main.add_child main_body
    main_body.add_child declare1
    main_body.add_child declare2
    main_body.add_child if_statement
    main_body.add_child return_stmt
    declare1.add_child number_decl
    declare2.add_child two_decl
    declare2.add_child three_decl
    declare2.add_child four_decl
    two_decl.add_child two_literal
    three_decl.add_child three_literal
    four_decl.add_child four_literal
    if_statement.add_child compare
    if_statement.add_child if_body
    if_statement.add_child else_body
    compare.add_child add
    compare.add_child implicit_cast4
    add.add_child implicit_cast1
    add.add_child multiply
    implicit_cast1.add_child variable_ref1
    multiply.add_child implicit_cast2
    implicit_cast2.add_child variable_ref2
    multiply.add_child implicit_cast3
    implicit_cast3.add_child variable_ref3
    implicit_cast4.add_child variable_ref4
    if_body.add_child set_value1
    set_value1.add_child variable_ref5
    set_value1.add_child implicit_cast6
    implicit_cast6.add_child variable_ref6
    else_body.add_child set_value2
    set_value2.add_child variable_ref7
    set_value2.add_child five_literal
    return_stmt.add_child implicit_cast8
    implicit_cast8.add_child variable_ref8

    ast
  end
end
