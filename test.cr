alias ValueType = String | Int32 | Float64 | Symbol | Nil

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
end

class Token
    getter typeT, value
    def initialize(@typeT : TokenType, 
                    @value : ValueType,
                    @line : Int32,
                    @column : Int32 )
    end
end

class Lexer
    getter tokens
    @max : Int32

    def initialize(@content : String)
        @index = 0
        @position = 1
        @line = 1
        @currentToken = ""
        @currentTLine = 0
        @currentTPosition = 0
        @context = Context::TopLevel
        @current = ' '
        @next = ' '
        @max = @content.size - 1
        @keywords = [:puts]
        @tokens = [] of Token
    end

    def nextLine : Nil
      @line += 1
      @position = 0
    end

    def moveIndex : Nil
      @index += 1
      @position += 1
    end

    def setPosition : Nil
      @currentTLine = @line
      @currentTPosition = @position
    end

    def enterMode(context : Context) : Nil
      @context = context
      setPosition
    end

    def enterModeGet(context : Context) : Nil
      @context = context
      setPosition
      @currentToken += @current
    end

    def generate : Nil
        while @index <= @max
            @current = @content[@index]
            if @current == "\n"[0]
                nextLine
            end
            if @index < @max
                @next = @content[@index + 1]
            else
                @next = '\u{4}'
            end
            parseCurrentChar
            moveIndex
        end
        closeToken
        @tokens << Token.new TokenType::Delimiter, :endf, @line, @position
    end

    def parseCurrentChar : Nil
        case @context
        when Context::TopLevel
            parseTopLevel
        when Context::Comment
            parseComment
        when Context::Identifier
            parseIdentifier
        when Context::String
            parseString
        when Context::Number
            parseNumber
        when Context::Operator
            parseOperator
        end
    end

    def parseComment : Nil
        if @current != '\n'
            @currentToken += @current
        else
            generateToken TokenType::Comment, @currentToken.strip
        end
    end

    def parseIdentifier : Nil
        if !@current.ascii_whitespace?
            @currentToken += @current
        else
            closeIdentifierToken
        end
    end

    def parseString : Nil
        if @current == "\\"[0]
            @current != '"'
            @currentToken += @next
            moveIndex
        elsif @current != '"'
            @currentToken += @current
        else
            generateToken TokenType::String, @currentToken.strip
        end
    end

    def parseNumber : Nil
        if @current.ascii_number? || @current == '.'
            @currentToken += @current
        elsif @current == '_'
        else
            closeNumberToken
        end
    end

    def parseOperator : Nil
        if !@current.ascii_whitespace?
            @currentToken += @current
        else
            generateToken TokenType::Operator, @currentToken.strip
        end
    end

    def parseTopLevel : Nil
        case
        when @current == "\n"[0]
            @tokens << Token.new TokenType::Delimiter, :endl, @line, @position
        when @current == '"'
            enterMode(Context::String)
        when @current == '#'
            enterMode(Context::Comment)
        when @current.ascii_letter?
            enterModeGet(Context::Identifier)
        when @current.ascii_number?
            enterModeGet(Context::Number)
        when !@current.ascii_whitespace?
            enterModeGet(Context::Operator)
        end
    end

    def closeToken : Nil
        if @currentToken.strip != ""
            case @context
            when Context::Number
                closeNumberToken
            when Context::Identifier
                closeIdentifierToken
            when Context::Comment
                generateToken TokenType::Comment, @currentToken.strip
            end
        end
    end

    def closeNumberToken : Nil
        number = @currentToken.strip
        if number.includes? "."
            generateToken TokenType::Float, number.to_f
        else
            generateToken TokenType::Int, number.to_i
        end
    end

    def closeIdentifierToken : Nil
        identifier = @currentToken.strip
        if @keywords.any? { |word| word.to_s == identifier }
            @keywords.each do |keyword|
                if keyword.to_s == identifier
                    generateToken TokenType::Keyword, keyword
                end
            end
        else
            generateToken TokenType::Identifier, identifier
        end
    end

    def generateToken(typeVal : TokenType, value : ValueType) : Nil
        @tokens << Token.new typeVal, value, @currentTLine, @currentTPosition
        @currentToken = ""
        @context = Context::TopLevel
    end
end

lexer = Lexer.new "puts \"Hello World!\""
lexer.generate
lexer.tokens.each do |token|
    pp token
end