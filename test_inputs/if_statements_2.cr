puts "starting"

if 2 < 5 - 3
  puts "ok1"
  if 10 != 5 * 2
    puts 1
  else
    puts 2
  end
  puts "ok2"
else
  puts "ok3"
  if 10 != 5 * 2
    puts 3
  else
    puts 4
  end
  puts "ok4"
end

puts "done"
