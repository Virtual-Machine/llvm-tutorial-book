#Chapter 3 Lexer

Finally it is time to begin with the actual design and implementation of our toy compiler. If you made it this far, then you know our first step in building a compiler is to create something known as a Lexer. The Lexer will be a component of our compiler. Its job is to take an array of character data and produce an array of tokens.

The Lexer will begin by taking the array of characters and looping through them one at a time. As it does so it will be keeping track of important information such as the line and column number for positioning, the current character, and the current token being parsed. When the Lexer either reaches a character indicating the end of a token, or the current token being parsed equals specific keywords or symbols it knows that it can parse the current token information. When the previous condition is reached, the Lexer adds a new Token to its Token array reflecting the parsed token information and then restarts the token processing algorithm where it left off.

Our Lexer will also have some additional properties to help it when parsing our language. One thing our Lexer will have is a context property. What this does is allow the Lexer to understand more complicated groupings of characters. For example we want our Lexer to recognize that the following grouping of characters: "Hello World!" is in fact one String token rather than two seperate tokens. An easy way to accomplish this is to use the context property to indicate when the Lexer has entered a String section so it knows to continue adding characters until the second quotation symbol is encountered. This context property can also be used to collate comments into a single Token.

The only remaining requirement for our Lexer is for it to inject some whitespace tokens during its work to aid the Parser. In order for the Parser to be able to clearly know when a given expression ends and a new one begins, our Lexer should append a new line token on each new line escape sequence, and to be explicit we will also append an end of file token once Lexing is complete. This way our array of tokens will clearly indicate the linear order of all the semantics of our programming language including the effects of whitespace on expressions.

With the details out of the way, lets begin our implementation:

```crystal
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
        @keywords = [:var]
        @tokens = [] of Token
    end
end

```

As you can see the basics of the Lexer object is just a bunch of instance variables to track state.

We will add a few helper methods to our object to aid our positional movement

```crystal
class Lexer
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
end
```

And a few helper methods to help handle context

```crystal
class Lexer
    #Note this version ignores the character while setting context
    def enterMode(context : Context) : Nil
      @context = context
      setPosition
    end

    #Note this version gets the character while setting context
    def enterModeGet(context : Context) : Nil
      @context = context
      setPosition
      @currentToken += @current
    end
end
```


Here we introduce the effective 'main' function for our Lexer class: generate. This function drives the Lexer through its input content to generate the output Token array.

```crystal
class Lexer
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
end
```

The parseCurrentChar function decides how to proceed for the current character. Its just a switch that calls the correct parse routine based on the current context.

```crystal
class Lexer
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
end
```

Here are the parse functions. None of them are too complex but read through and figure out how they are getting the values of the tokens.

```crystal
class Lexer
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
end
```

Finally we add the last few functions our Lexer needs, which helps to close out and generate the tokens.

```crystal
class Lexer
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

```
