class Verifier
  def initialize
  end

  def verify_token_array(token_array : Array(Token)) : Nil
    verify_token_array_pairs token_array
  end

  def verify_token_array_pairs(token_array : Array(Token)) : Nil
    pair_max = token_array.size - 2
    token_array.each_with_index do |token, index|
      if index <= pair_max
        next_token = token_array[index + 1]

        check_for_invalid_token_pairs token, next_token
      end
    end
  end

  def check_for_invalid_token_pairs(token, next_token)
    case token.typeT
    when TokenType::Operator
      if next_token.typeT == TokenType::Operator || next_token.typeT == TokenType::ParenClose
        build_and_raise_verification_error token, next_token
      end
    when TokenType::ParenOpen
      if next_token.typeT == TokenType::Operator
        build_and_raise_verification_error token, next_token
      end
    when TokenType::ParenClose
      case next_token.typeT
      when TokenType::Int, TokenType::Float, TokenType::String, TokenType::Bool, TokenType::Symbol, TokenType::ParenOpen
        build_and_raise_verification_error token, next_token
      end
    when TokenType::Int, TokenType::Float, TokenType::String, TokenType::Bool, TokenType::Symbol
      case next_token.typeT
      when TokenType::Int, TokenType::Float, TokenType::String, TokenType::Bool, TokenType::Symbol, TokenType::ParenOpen
        build_and_raise_verification_error token, next_token
      end
    end
  end

  def build_and_raise_verification_error(token, next_token)
    if token.typeT == TokenType::String
      token_value = "\"#{token.value}\""
    else
      token_value = token.value
    end
    if next_token.typeT == TokenType::String
      next_token_value = "\"#{next_token.value}\""
    else
      next_token_value = next_token.value
    end
    error_string = "Two tokens   #{token_value}   #{next_token_value}   were detected in sequence, this is not valid Emerald syntax"
    error = EmeraldTokenVerificationException.new error_string, token.line, token.column
    raise error
  end
end
