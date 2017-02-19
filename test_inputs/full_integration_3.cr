def repeater(x Int32, y String) String
  while x > 0
    puts y
    x = x - 1
    if x == 3
    	return "Hello"
    end
  end
  return "Goodbye"
end

def ifthen(x Int32) Bool
	if x > 5
		puts "Yuge!"
		return true
	else
		puts "Not so biggly"
		return false
	end
end

def combo(x Int32, y Float64) Float64
	if y > 3.4
		if x > 0
			while x > 0 
				puts y
				return y
			end
		end
	end
	return 0.0
end

puts repeater 4, "Hellos"
puts repeater 2, "Hellos"
puts ifthen 7
puts ifthen 3
puts combo 5, 6.7
puts combo 1, 3.4