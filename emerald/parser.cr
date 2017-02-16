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

  def parse_token : Nil
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
      elsif @current_token.value == :def
        parse_function_definition
      elsif @current_token.value == :return
        parse_return
      elsif @current_token.value == :if
        parse_if
      elsif @current_token.value == :else
        parse_else
      elsif @current_token.value == :end
        parse_end
      elsif @current_token.value == :while
        parse_while
      end
    when TokenType::FuncCall
      parse_function_call
    when TokenType::Comma
      parse_comma
    when TokenType::Comment
    when TokenType::Delimiter
      if @paren_nest == 0
        @active_node = active_context
        if @active_node.class == IfExpressionNode
          if @active_node.children.size == 1
            node = BasicBlockNode.new @current_token.line, @current_token.column
            add_and_activate node
          elsif @active_node.children.size == 2
            @active_node = @active_node.children[1]
          elsif @active_node.children.size == 3
            @active_node = @active_node.children[2]
          end
        elsif @active_node.class == WhenExpressionNode
          if @active_node.children.size == 1
            node = BasicBlockNode.new @current_token.line, @current_token.column
            add_and_activate node
          else
            @active_node = @active_node.children[1]
          end
        end
      end
    else
      raise EmeraldParsingException.new "#{@current_token.typeT} is not currently supported at the top level", @current_token.line, @current_token.column
    end
  end

  def add_and_activate(node : Node) : Nil
    @active_node.add_child node
    @active_node = node
  end

  def add_expression_node(parens : Bool = false) : Nil
    node = ExpressionNode.new parens, @current_token.line, @current_token.column
    add_and_activate node
  end

  def parse_int : Nil
    if @active_node == @ast[0]
      add_expression_node
    end
    node = IntegerLiteralNode.new @current_token.value.as(Int32), @current_token.line, @current_token.column
    add_and_activate node
  end

  def parse_string : Nil
    if @active_node == @ast[0]
      add_expression_node
    end
    node = StringLiteralNode.new @current_token.value.as(String), @current_token.line, @current_token.column
    add_and_activate node
  end

  def parse_float : Nil
    if @active_node == @ast[0]
      add_expression_node
    end
    node = FloatLiteralNode.new @current_token.value.as(Float64), @current_token.line, @current_token.column
    add_and_activate node
  end

  def parse_bool : Nil
    if @active_node == @ast[0]
      add_expression_node
    end
    node = BooleanLiteralNode.new @current_token.value.as(Bool), @current_token.line, @current_token.column
    add_and_activate node
  end

  def parse_operator : Nil
    if @active_node == @ast[0]
      raise EmeraldParsingException.new "#{@current_token.typeT} is not currently supported at the top level", @current_token.line, @current_token.column
    end
    node = BinaryOperatorNode.new @current_token.value.as(String), @current_token.line, @current_token.column
    @active_node.promote node
    @active_node = node
  end

  def parse_paren_open : Nil
    @paren_nest += 1
    add_expression_node true
  end

  def parse_paren_close : Nil
    @paren_nest -= 1
    if @paren_nest < 0
      raise EmeraldParsingException.new "Closing parenthesis without corresponding opening parenthesis in expression", @tokens[0].line, @tokens[0].column
    end
    @active_node = @active_node.get_first_parens_node
  end

  def parse_variable_declaration : Nil
    identifier = @current_token.value
    node = VariableDeclarationNode.new identifier.as(String), @current_token.line, @current_token.column
    add_and_activate node
    add_expression_node
    @tokens.shift
  end

  def parse_declaration_reference : Nil
    node = DeclarationReferenceNode.new @current_token.value.as(String), @current_token.line, @current_token.column
    add_and_activate node
  end

  def parse_builtin_puts : Nil
    node = CallExpressionNode.new "puts", @current_token.line, @current_token.column
    add_and_activate node
    add_expression_node
  end

  def parse_if : Nil
    node = IfExpressionNode.new @current_token.line, @current_token.column
    add_and_activate node
    @context.push node
    add_expression_node
  end

  def parse_while : Nil
    node = WhenExpressionNode.new @current_token.line, @current_token.column
    add_and_activate node
    @context.push node
    add_expression_node
  end

  def parse_else : Nil
    @active_node = @active_node.parent.not_nil!
    node = BasicBlockNode.new @current_token.line, @current_token.column
    add_and_activate node
  end

  def parse_end : Nil
    @context.pop
    @active_node = active_context
  end

  def parse_return : Nil
    node = ReturnNode.new @current_token.line, @current_token.column
    add_and_activate node
    add_expression_node
  end

  def parse_function_definition : Nil
    @tokens.shift
    line = @tokens[0].line
    column = @tokens[0].column
    name = @tokens[0].value.as(String)
    params = {} of String => Symbol
    @tokens.shift
    if @tokens[0].typeT == TokenType::ParenOpen
      if @tokens[1].typeT == TokenType::ParenClose
        # Jump over empty parens
        @tokens.shift
        @tokens.shift
      else
        # Parse identifier / type pairs
        until @tokens[0].typeT == TokenType::ParenClose
          @tokens.shift
          if @tokens[0].typeT == TokenType::Identifier && @tokens[1].typeT == TokenType::Type
            params[@tokens[0].value.as(String)] = @tokens[1].value.as(Symbol)
          else
            raise EmeraldParsingException.new "Function #{name} has an invalid declaration.\nWhen declaring parameters, you must provide an identifier and type and seperate with commas\nExample: def add_xy(x Int32, y Int32) Int32", @tokens[0].line, @tokens[0].column
          end
          @tokens.shift
          @tokens.shift
        end
        @tokens.shift
      end
    elsif @tokens[0].typeT == TokenType::Type
      # No parens
    else
      raise EmeraldParsingException.new "Function #{name} has an invalid declaration.\nOnly an opening parenthesis or a type can follow the name of a function.", @tokens[0].line, @tokens[0].column
    end
    if @tokens[0].typeT != TokenType::Type
      raise EmeraldParsingException.new "Function #{name} has an invalid declaration.\nNo return type is present.", @tokens[0].line, @tokens[0].column
    end
    return_type = @tokens[0].value.as(Symbol)
    @tokens.shift
    node = FunctionDeclarationNode.new name, params, return_type, line, column
    add_and_activate node
    body = BasicBlockNode.new @tokens[1].line, @tokens[1].column
    add_and_activate body
    @context.push body
  end

  def parse_function_call : Nil
    node = CallExpressionNode.new @current_token.value.as(String), @current_token.line, @current_token.column
    add_and_activate node
    add_expression_node
  end

  def parse_comma : Nil
    @active_node = @active_node.get_first_expression_node.parent
    add_expression_node
  end
end
