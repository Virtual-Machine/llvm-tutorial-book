class EmeraldSyntaxException < Exception
  getter line

  def initialize(@message : String, @line : Int32, @column : Int32)
  end

  def to_s : String
    "#{self.class} <#{@line}:#{@column}> : #{@message}"
  end

  def to_s_coloured : String
    "\033[031m#{self.class}\033[039m <\033[034m#{@line}\033[039m:\033[034m#{@column}\033[039m> : #{@message}"
  end

  def full_error(source : String, color : Bool, test_mode : Bool) : Nil
    if test_mode
      raise self
    else
      color ? puts self.to_s_coloured : puts self.to_s
      puts

      lines = source.split("\n")

      print_pre_line = self.line == 1 ? false : true
      print_post_line = self.line == lines.size ? false : true

      puts "Line #{self.line - 1} : #{lines[self.line - 2].strip}" if print_pre_line
      color ? puts "\033[031mLine #{self.line} :\033[039m #{lines[self.line - 1].strip}" : puts "Line #{self.line} : #{lines[self.line - 1].strip}"
      puts "Line #{self.line + 1} : #{lines[self.line].strip}" if print_post_line
      exit 1
    end
  end
end

class EmeraldValueResolutionException < EmeraldSyntaxException
end

class EmeraldTokenVerificationException < EmeraldSyntaxException
end

class EmeraldLexingException < EmeraldSyntaxException
end

class EmeraldParsingException < EmeraldSyntaxException
end

class EmeraldVariableReferenceException < EmeraldSyntaxException
end

class EmeraldInstructionException < EmeraldSyntaxException
end
