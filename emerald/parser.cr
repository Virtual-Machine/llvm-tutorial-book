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
    @context = [@ast[0]] of Node
    @current_token = @tokens[0]
    @paren_nest = 0
  end

  def active_context : Node
    @context[-1]
  end

  def parse : Array(Node)
    while @tokens.size > 0
      @current_token = @tokens[0]
      if @tokens.size > 1
        @next_token = @tokens[1]
      end
      parse_token

      @tokens.shift
    end
    if @paren_nest > 0
      raise EmeraldParsingException.new "Unclosed parenthesis expression", 0, 0
    end
    @ast
  end

  def parse_token
    case @current_token.typeT
    when TokenType::Int
      parse_int
    when TokenType::String
      parse_string
    when TokenType::Float
      parse_float
    when TokenType::Bool
      parse_bool
    when TokenType::ParenOpen
      parse_paren_open
    when TokenType::ParenClose
      parse_paren_close
    when TokenType::Operator
      parse_operator
    when TokenType::Identifier
      if @next_token.not_nil!.typeT == TokenType::Operator && @next_token.not_nil!.value == "="
        parse_variable_declaration
      else
        parse_declaration_reference
      end
    when TokenType::Keyword
      if @current_token.value == :puts
        parse_builtin_puts
      elsif @current_token.value == :return
        parse_return
      end
    when TokenType::Comment
    when TokenType::Delimiter
      if @paren_nest == 0
        @active_node = active_context
      end
    else
      raise EmeraldParsingException.new "#{@current_token.typeT} is not currently supported at the top level", @current_token.line, @current_token.column
    end
  end

  def add_and_activate(node : Node) : Nil
    @active_node.add_child node
    @active_node = node
  end

  def add_expression_node : Nil
    node = ExpressionNode.new @current_token.line, @current_token.column
    add_and_activate node
  end

  def parse_int
    if @active_node == @ast[0]
      add_expression_node
    end
    node = IntegerLiteralNode.new @current_token.value.as(Int32), @current_token.line, @current_token.column
    add_and_activate node
  end

  def parse_string
    if @active_node == @ast[0]
      add_expression_node
    end
    node = StringLiteralNode.new @current_token.value.as(String), @current_token.line, @current_token.column
    add_and_activate node
  end

  def parse_float
    if @active_node == @ast[0]
      add_expression_node
    end
    node = FloatLiteralNode.new @current_token.value.as(Float64), @current_token.line, @current_token.column
    add_and_activate node
  end

  def parse_bool
    if @active_node == @ast[0]
      add_expression_node
    end
    node = BooleanLiteralNode.new @current_token.value.as(Bool), @current_token.line, @current_token.column
    add_and_activate node
  end

  def parse_operator
    if @active_node == @ast[0]
      raise EmeraldParsingException.new "#{@current_token.typeT} is not currently supported at the top level", @current_token.line, @current_token.column
    end
    node = BinaryOperatorNode.new @current_token.value.as(String), @current_token.line, @current_token.column
    @active_node.promote node
    @active_node = node
  end

  def parse_paren_open
    @paren_nest += 1
    add_expression_node
  end

  def parse_paren_close
    @paren_nest -= 1
    if @paren_nest < 0
      raise EmeraldParsingException.new "Closing parenthesis without corresponding opening parenthesis in expression", @tokens[0].line, @tokens[0].column
    end
    @active_node = @active_node.get_first_expression_node
  end

  def parse_variable_declaration
    identifier = @current_token.value
    node = VariableDeclarationNode.new identifier.as(String), @current_token.line, @current_token.column
    add_and_activate node
    add_expression_node
    @tokens.shift
  end

  def parse_declaration_reference
    node = DeclarationReferenceNode.new @current_token.value.as(String), @current_token.line, @current_token.column
    add_and_activate node
  end

  def parse_builtin_puts
    node = CallExpressionNode.new "puts", @current_token.line, @current_token.column
    add_and_activate node
    add_expression_node
  end

  def parse_return
    node = ReturnNode.new @current_token.line, @current_token.column
    add_and_activate node
    add_expression_node
  end
end
