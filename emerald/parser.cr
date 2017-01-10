class Parser
  getter ast
  property active_node

  @max : Int32
  @current_token : Token
  @next_token : Token?
  @active_node : Node

  def initialize(@tokens : Array(Token))
    @ast = [] of Node
    @current_index = 0
    @max = @tokens.size - 1
    @current_token = @tokens[0]
    @look_ahead = 0
    ast.push RootNode.new
    @active_node = @ast[0]
  end

  def parse : Array(Node)
    while @current_index < @max
      @current_token = @tokens[@current_index]
      @next_token = @tokens[@current_index + 1]
      
      parse_top_level

      @current_index += 1
    end
    @ast
  end

  def parse_top_level
    case @current_token.typeT
    when TokenType::Identifier
      if @next_token.not_nil!.typeT == TokenType::Operator && @next_token.not_nil!.value == "="
        parse_identifier_declaration
      end
    when TokenType::Keyword
      if @current_token.value == :puts
        puts_node = CallExpressionNode.new "puts", @current_token.line, @current_token.column
        @active_node.add_child puts_node
        @active_node = puts_node
        parsed_expression = parse_expression (isolate_expression 1)
        @active_node.add_child parsed_expression
      end
    when TokenType::Delimiter
      @active_node = @ast[0]
    end
  end

  def parse_identifier_declaration
    identifier = @current_token.value
    var_decl = VariableDeclarationNode.new identifier, @current_token.line, @current_token.column
    @active_node.add_child var_decl
    @active_node = var_decl
    parsed_expression = parse_expression (isolate_expression 2)
    @active_node.add_child parsed_expression
  end


  def isolate_expression(look_ahead : Int32) : Array(Token)
    initial_index = look_ahead + @current_index
    while @tokens[@current_index + look_ahead].typeT != TokenType::Delimiter
      look_ahead += 1
    end
    range = look_ahead + @current_index - initial_index
    @tokens[initial_index, range]
  end

  def parse_expression(tokens : Array(Token)) : Node
    root = ExpressionNode.new @current_token.line, @current_token.column
    active = root
    tokens.each do |token|
      case token.typeT
      when TokenType::Int
        int_node = IntegerLiteralNode.new token.value, token.line, token.column
        active.add_child int_node
        active = int_node
      when TokenType::Identifier
        ident_node = DeclarationReferenceNode.new token.value, token.line, token.column
        active.add_child ident_node
        active = ident_node
      when TokenType::Operator
        operator = BinaryOperatorNode.new token.value, token.line, token.column
        active.promote operator
        active = operator
      end
    end
    root
  end
end
