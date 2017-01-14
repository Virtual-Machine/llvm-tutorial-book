require "option_parser"
require "./emerald/emerald"

test_runner = false
clean = false
full = false
execute = false
help = false

options = {
  "color"             => true,
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
  # acdefhinrstv options

  # Test Runner
  parser.on("-tr", "--test-runner", "Run all tests in spec") { test_runner = true }

  # No Colors
  parser.on("-n", "--no_colors", "Turn off colourized output") { options["color"] = false }

  # Help
  parser.on("-h", "--help", "Print Help") { puts parser.to_s; help = true }

  # Clean
  parser.on("-c", "--clean", "Cleans out all output files") { clean = true }

  # Full Build
  parser.on("-f", "--full", "Fully compile to runnable binary") { full = true }
  parser.on("-e", "--execute", "Fully compile and execute runnable binary") { execute = true }

  # Output
  parser.on("-s", "--supress", "Supress output.ll generation") { options["supress"] = true }

  # Debug Verbosity
  parser.on("-t", "--token_array", "Prints token array to aid debugging") { options["printTokens"] = true }
  parser.on("-a", "--ast", "Prints AST to aid debugging") { options["printAST"] = true }
  parser.on("-r", "--resolutions", "Prints AST resolutions to aid debugging") { options["printResolutions"] = true }
  parser.on("-i", "--instructions", "Prints instructions to aid debugging") { options["printInstructions"] = true }
  parser.on("-v", "--verbose", "Prints output to aid debugging") { options["printOutput"] = true }
  parser.on("-d", "--debug", "Full debug output, = -t -a -r -i -v") { 
    options["printTokens"] = true
    options["printAST"] = true
    options["printResolutions"] = true
    options["printInstructions"] = true
    options["printOutput"] = true
  }
  # Filename
  parser.unknown_args do |item|
    if item.size > 0
      options["filename"] = item[0]
    end
  end
end

if clean
  File.delete("./output.ll") if File.file?("./output.ll")
  File.delete("./output.s") if File.file?("./output.s")
  File.delete("./output") if File.file?("./output")
elsif help
elsif test_runner
  files = Dir.open Dir.current + "/spec/"
  files.each do |file|
    if File.extname(file) == ".ll"
      File.delete Dir.current + "/spec/#{file}"
    end
  end
  system "crystal spec spec/*"
else
  # Compilation
  program = EmeraldProgram.new options
  program.compile
  if full || execute
    system "llc output.ll"
    system "clang output.s -o output"
    if execute
      system "./output"
    end
  end
end
