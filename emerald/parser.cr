class Parser
  getter ast
  property active_node

  @active_node : Node
  @current_token : Token
  @next_token : Token?

  def initialize(@tokens : Array(Token))
    @ast = [] of Node
    ast.push RootNode.new
    @active_node = @ast[0]
    @current_token = @tokens[0]
  end

  def parse : Array(Node)
    while @tokens.size > 0
    	@current_token = @tokens[0]
    	if @tokens.size > 1
    		@next_token = @tokens[1]
    	end

    	parse_top_level

    	@tokens.shift
    	@active_node = @ast[0]
    end
    @ast
  end

  def parse_top_level
    case @current_token.typeT
    when TokenType::Int
      parsed_expression = parse_expression (isolate_expression 0)
      @active_node.add_child parsed_expression
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
    look_ahead.times do
    	@tokens.shift
    end
    expression = [] of Token
    until @tokens[0].typeT == TokenType::Delimiter

    	expression.push @tokens.shift
    end
    expression
  end

  def parse_expression(tokens_exp : Array(Token)) : Node
    root = ExpressionNode.new @current_token.line, @current_token.column
    active = root
    tokens_exp.each do |token|
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
