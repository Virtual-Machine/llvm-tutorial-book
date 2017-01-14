class Verifier
	def initialize
	end

	def verify_token_array(token_array : Array(Token))
		verify_token_array_pairs token_array
	end

	def verify_token_array_pairs(token_array : Array(Token))
		pair_max = token_array.size - 2
		token_array.each_with_index do |token, index|
			if index <= pair_max
				next_token = token_array[index + 1]
				
				if token.typeT == TokenType::Operator && next_token.typeT == TokenType::Operator
					emerald_syntax_error token.line, token.column, "Two tokens   #{token.value}   #{next_token.value}   were detected in sequence, this is not valid Emerald syntax"
				end
				
				if token.typeT == TokenType::ParenOpen && next_token.typeT == TokenType::Operator
					emerald_syntax_error token.line, token.column, "Two tokens   #{token.value}   #{next_token.value}   were detected in sequence, this is not valid Emerald syntax"
				end

				if token.typeT == TokenType::Operator && next_token.typeT == TokenType::ParenClose
					emerald_syntax_error token.line, token.column, "Two tokens   #{token.value}   #{next_token.value}   were detected in sequence, this is not valid Emerald syntax"
				end				
			end
		end
	end

	def emerald_syntax_error(line, column, message)
		raise EmeraldSyntaxException.new message, line, column
	end
end