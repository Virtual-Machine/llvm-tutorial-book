class Lexer
  getter tokens
  @max : Int32

  def initialize(@content : String)
    @index = 0
    @position = 1
    @line = 1
    @current_token = ""
    @current_t_line = 0
    @current_t_position = 0
    @context = Context::TopLevel
    @current = ' '
    @next = ' '
    @max = @content.size - 1
    @keywords = [:puts, :return, :true, :false]
    @tokens = [] of Token
  end

  def next_line : Nil
    @line += 1
    @position = 0
  end

  def move_index : Nil
    @index += 1
    @position += 1
  end

  def set_position : Nil
    @current_t_line = @line
    @current_t_position = @position
  end

  def enter_mode(context : Context) : Nil
    @context = context
    set_position
  end

  def enter_mode_get(context : Context) : Nil
    @context = context
    set_position
    @current_token += @current
  end

  def lex : Array(Token)
    while @index <= @max
      @current = @content[@index]
      if @index < @max
        @next = @content[@index + 1]
      else
        @next = '\u{4}'
      end
      lex_current_char
      if @current == '\n'
        @tokens << Token.new TokenType::Delimiter, :endl, @line, @position
        next_line
      end
      move_index
    end
    close_token
    @tokens << Token.new TokenType::Delimiter, :endf, @line, @position
  end

  def lex_current_char : Nil
    if (@current == '(' || @current == ')') && @context != Context::Comment
      lex_parens
    else
      case @context
      when Context::TopLevel
        lex_top_level
      when Context::Comment
        lex_comment
      when Context::Identifier
        lex_identifier
      when Context::String
        lex_string
      when Context::Number
        lex_number
      when Context::Operator
        lex_operator
      end
    end
  end

  def lex_parens : Nil
    if @current == '('
      @tokens << Token.new TokenType::ParenOpen, "(", @line, @position
    elsif @current == ')'
      close_token
      @tokens << Token.new TokenType::ParenClose, ")", @line, @position
    end
  end

  def lex_comment : Nil
    if @current != '\n'
      @current_token += @current
    else
      generate_token TokenType::Comment, @current_token.strip
    end
  end

  def lex_identifier : Nil
    if !@current.ascii_whitespace?
      @current_token += @current
    else
      close_identifier_token
    end
  end

  def lex_string : Nil
    if @current == '\\'
      @current_token += @next
      move_index
    elsif @current != '"'
      @current_token += @current
    else
      generate_token TokenType::String, @current_token
    end
  end

  def lex_number : Nil
    if @current.ascii_number? || @current == '.'
      @current_token += @current
    elsif @current == '_'
    else
      close_number_token
    end
  end

  def lex_operator : Nil
    if !@current.ascii_whitespace? && @current != '(' && @current != ')'
      @current_token += @current
    else
      generate_token TokenType::Operator, @current_token.strip
    end
  end

  def lex_top_level : Nil
    case
    when @current == '\n'
      @tokens << Token.new TokenType::Delimiter, :endl, @line, @position
    when @current == '"'
      enter_mode(Context::String)
    when @current == '#'
      enter_mode(Context::Comment)
    when @current.ascii_letter?
      enter_mode_get(Context::Identifier)
    when @current.ascii_number?
      enter_mode_get(Context::Number)
    when !@current.ascii_whitespace?
      enter_mode_get(Context::Operator)
    end
  end

  def close_token : Nil
    if @current_token.strip != ""
      case @context
      when Context::Number
        close_number_token
      when Context::Identifier
        close_identifier_token
      when Context::Operator
        generate_token TokenType::Operator, @current_token.strip
      when Context::Comment
        generate_token TokenType::Comment, @current_token.strip
      end
    end
  end

  def close_number_token : Nil
    number = @current_token.strip
    if number.includes? "."
      generate_token TokenType::Float, number.to_f
    else
      generate_token TokenType::Int, number.to_i
    end
  end

  def close_identifier_token : Nil
    identifier = @current_token.strip
    if @keywords.any? { |word| word.to_s == identifier }
      @keywords.each do |keyword|
        if keyword.to_s == identifier
          if keyword == :true
            generate_token TokenType::Bool, true
          elsif keyword == :false
            generate_token TokenType::Bool, false
          else
            generate_token TokenType::Keyword, keyword
          end
        end
      end
    else
      generate_token TokenType::Identifier, identifier
    end
  end

  def generate_token(typeVal : TokenType, value : ValueType) : Nil
    @tokens << Token.new typeVal, value, @current_t_line, @current_t_position
    @current_token = ""
    @context = Context::TopLevel
  end
end
