class EmeraldSyntaxException < Exception
	getter line

	def initialize(@message : String, @line : Int32, @column : Int32)
	end

	def to_s
		"#{self.class} <#{@line}:#{@column}> : #{@message}"
	end
end