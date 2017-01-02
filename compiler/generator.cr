class Generator
  getter output

  def initialize(@ast : AST)
    @output = ""
  end

  def generate : Nil
  end
end
