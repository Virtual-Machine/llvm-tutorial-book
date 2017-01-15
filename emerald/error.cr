class EmeraldSyntaxException < Exception
	getter line

	def initialize(@message : String, @line : Int32, @column : Int32)
	end

	def to_s
		"#{self.class} <#{@line}:#{@column}> : #{@message}"
	end

	def to_s_coloured
		"\033[031m#{self.class}\033[039m <\033[034m#{@line}\033[039m:\033[034m#{@column}\033[039m> : #{@message}"
	end

	def full_error(source : String, color : Bool, test_mode : Bool)
		if test_mode
			raise self
		else
			if color
				puts self.to_s_coloured
			else
				puts self.to_s 
			end

			puts

			lines = source.split("\n")
			
			print_pre_line = true
			print_post_line = true
			if self.line == 1
				print_pre_line = false
			end
			if self.line == lines.size
				print_post_line = false
			end
			
			puts "Line #{self.line - 1} : #{lines[self.line - 2]}" if print_pre_line
			if color
				puts "\033[031mLine #{self.line} :\033[039m #{lines[self.line - 1]}"
			else
				puts "Line #{self.line} : #{lines[self.line - 1]}"
			end
			puts "Line #{self.line + 1} : #{lines[self.line]}" if print_post_line
			exit 1
		end
	end
end

class EmeraldValueResolutionException < EmeraldSyntaxException
end

class EmeraldTokenVerificationException < EmeraldSyntaxException
end