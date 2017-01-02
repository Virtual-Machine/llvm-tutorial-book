class Parser
  getter ast

  @max : Int32
  @current_token : Token

  def initialize(@tokens : Array(Token))
    @ast = [] of Node
    @current_index = 0
    @current_token = @tokens[0]
    @max = @tokens.size - 1
    @look_ahead = 0
  end

  def inspect : Nil
    @ast.each do |node|
      puts node.inspect
    end
  end

  def parse : Nil
    while @current_index < @max
      @current_token = @tokens[@current_index]
      case @current_token.typeT
      when TokenType::Keyword
        case @current_token.value
        when :puts
          parseCallExpression
        else
          raise "Undefined keyword"
        end
      else
      end
      # pp @current_token
      @current_index += 1
    end
  end

  def parseCallExpression : Nil
    while @tokens[@current_index + @look_ahead].typeT != TokenType::Delimiter
      @look_ahead += 1
    end
  end
end
