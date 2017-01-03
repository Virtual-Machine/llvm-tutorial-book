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
    @ast.push ExpressionsNode.new @current_token.line, @current_token.column
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
      @current_index += 1
    end
  end

  def parseCallExpression : Nil
    statement = @current_token.value.to_s
    @look_ahead = 1
    while @tokens[@current_index + @look_ahead].typeT != TokenType::Delimiter
      statement += " #{@tokens[@current_index + @look_ahead].value.to_s}"
      @look_ahead += 1
    end
    puts statement
  end
end
