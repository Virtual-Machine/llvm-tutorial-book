require "option_parser"
require "./emerald/emerald"

clean = false
full = false

options = {
  "supress"           => false,
  "printTokens"       => false,
  "printAST"          => false,
  "printResolutions"  => false,
  "printInstructions" => false,
  "printOutput"       => false,
  "filename"          => "test_file.cr",
}

OptionParser.parse! do |parser|
  parser.banner = "Usage: emeraldc [file_name] [flags]"

  # Clean
  parser.on("-c", "--clean", "Cleans out all output files") { clean = true }

  # Full Build
  parser.on("-f", "--full", "Fully compile to runnable binary") { full = true }

  # Output
  parser.on("-s", "--supress", "Supress output.ll generation") { options["supress"] = true }

  # Debug Verbosity
  parser.on("-t", "--token_array", "Prints token array to aid debugging") { options["printTokens"] = true }
  parser.on("-a", "--ast", "Prints AST to aid debugging") { options["printAST"] = true }
  parser.on("-r", "--resolutions", "Prints AST resolutions to aid debugging") { options["printResolutions"] = true }
  parser.on("-i", "--instructions", "Prints instructions to aid debugging") { options["printInstructions"] = true }
  parser.on("-v", "--verbose", "Prints output to aid debugging") { options["printOutput"] = true }
  # Filename
  parser.unknown_args do |item|
    if item.size > 0
      filename = item[0]
    end
  end
end

if clean
  File.delete("./output.ll") if File.file?("./output.ll")
  File.delete("./output.s") if File.file?("./output.s")
  File.delete("./output") if File.file?("./output")
else
  # Compilation
  program = EmeraldProgram.new options
  program.compile
  if full
    system "llc output.ll"
    system "clang output.s -o output"
  end
end
