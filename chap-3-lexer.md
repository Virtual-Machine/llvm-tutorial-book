#Chapter 3 Lexer

Finally it is time to begin with the actual design and implementation of our toy compiler. If you made it this far, then you know our first step in building a compiler is to create something known as a Lexer. The Lexer will be a component of our compiler. Its job is to take an array of character data and produce an array of tokens.

The Lexer will begin by taking the array of characters and looping through them one at a time. As it does so it will be keeping track of important information such as the line and column number for positioning, the current character, and the current token being parsed. When the Lexer either reaches a character indicating the end of a token, or the current token being parsed equals specific keywords or symbols it knows that it can parse the current token information. When the previous condition is reached, the Lexer adds a new Token to its Token array reflecting the parsed token information and then restarts the token processing algorithm where it left off.

Our Lexer will also have some additional properties to help it when parsing our language. One thing our Lexer will have is a context property. What this does is allow the Lexer to understand more complicated groupings of characters. For example we want our Lexer to recognize that the following grouping of characters: "Hello World!" is in fact one String token rather than two seperate tokens. An easy way to accomplish this is to use the context property to indicate when the Lexer has entered a String section so it knows to continue adding characters until the second quotation symbol is encountered. This context property can also be used to collate comments into a single Token.

The only remaining requirement for our Lexer is for it to inject some whitespace tokens during its work to aid the Parser. In order for the Parser to be able to clearly know when a given expression ends and a new one begins, our Lexer should append a new line token on each new line escape sequence, and to be explicit we will also append an end of file token once Lexing is complete. This way our array of tokens will clearly indicate the linear order of all the semantics of our programming language including the effects of whitespace on expressions.

With the details out of the way, lets begin our implementation:

First we are going to add an alias and enums just to make our references cleaner and type safe. We are also going to implement a basic Token class that the Lexer will use to fill its Token array.

```crystal
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
```

And here is our actual Lexer:

```crystal
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
        @keywords = [:puts]
        @tokens = [] of Token
    end
end

```

As you can see the basics of the Lexer object is just a bunch of instance variables to track state.

We will add a few helper methods to our object to aid our positional movement

```crystal
class Lexer
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
end
```

And a few helper methods to help handle context

```crystal
class Lexer
    #Note this version ignores the character while setting context
    def enter_mode(context : Context) : Nil
      @context = context
      set_position
    end

    #Note this version gets the character while setting context
    def enter_mode_get(context : Context) : Nil
      @context = context
      set_position
      @current_token += @current
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
                next_line
            end
            if @index < @max
                @next = @content[@index + 1]
            else
                @next = '\u{4}'
            end
            lex_current_char
            move_index
        end
        close_token
        @tokens << Token.new TokenType::Delimiter, :endf, @line, @position
    end
end
```

The lex_current_char function decides how to proceed for the current character. Its just a switch that calls the correct lex routine based on the current context.

```crystal
class Lexer
    def lex_current_char : Nil
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
```

Here are the lex functions. None of them are too complex but read through and figure out how they are getting the values of the tokens.

```crystal
class Lexer
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
        if @current == "\\"[0]
            @current != '"'
            @current_token += @next
            move_index
        elsif @current != '"'
            @current_token += @current
        else
            generate_token TokenType::String, @current_token.strip
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
        if !@current.ascii_whitespace?
            @current_token += @current
        else
            generate_token TokenType::Operator, @current_token.strip
        end
    end
end
```

Finally we add the last few functions our Lexer needs, which helps to close out and generate the tokens.

```crystal
class Lexer
    def close_token : Nil
        if @current_token.strip != ""
            case @context
            when Context::Number
                close_number_token
            when Context::Identifier
                close_identifier_token
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
                    generate_token TokenType::Keyword, keyword
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

```

Here is a full listing of the compiler so far:
```crystal
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
        @current_token = ""
        @current_t_line = 0
        @current_t_position = 0
        @context = Context::TopLevel
        @current = ' '
        @next = ' '
        @max = @content.size - 1
        @keywords = [:puts]
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

    def generate : Nil
        while @index <= @max
            @current = @content[@index]
            if @current == "\n"[0]
                next_line
            end
            if @index < @max
                @next = @content[@index + 1]
            else
                @next = '\u{4}'
            end
            lex_current_char
            move_index
        end
        close_token
        @tokens << Token.new TokenType::Delimiter, :endf, @line, @position
    end

    def lex_current_char : Nil
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
        if @current == "\\"[0]
            @current != '"'
            @current_token += @next
            move_index
        elsif @current != '"'
            @current_token += @current
        else
            generate_token TokenType::String, @current_token.strip
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
        if !@current.ascii_whitespace?
            @current_token += @current
        else
            generate_token TokenType::Operator, @current_token.strip
        end
    end

    def lex_top_level : Nil
        case
        when @current == "\n"[0]
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
                    generate_token TokenType::Keyword, keyword
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
```

You can now use this class to generate a token array from a string of Emerald syntax. For example:
```crystal
lexer = Lexer.new "puts \"Hello World!\""
lexer.generate
lexer.tokens.each do |token|
    pp token
end
```

Will generate something like:
```
token # => #<Token:0x103aeff00 @typeT=Keyword, @value=:puts, @line=1, @column=1>
token # => #<Token:0x103aefed0 @typeT=String, @value="Hello World!", @line=1, @column=6>
token # => #<Token:0x103aefea0 @typeT=Delimiter, @value=:endf, @line=1, @column=20>
```

Congratulations. You have successfully made a lexer. Yes it is pretty basic right now but it will serve our purposes. We can easily graft on more language features as needed to the lexer. For example new keywords can be added to Lexer@keywords, or new Contexts could be created with correlating lex logic added in the relevant places. The important thing is we are easily able to inject strings into the lexer and visually inspect the array of tokens. This will be an important debugging tool when developing new syntax features. We are now ready to begin building our parser to transform the Token array into an AST.