def repeater(x Int32, y String) Nil
  while x > 0
    puts y
    x = x - 1
  end
end

def ifthen(x Int32) Nil
	if x > 5
		puts "Yuge!"
	else
		puts "Not so biggly"
	end
end

def combo(x Int32, y Float64) Nil
	if y > 3.4
		if x > 0
			while x > 0 
				puts y
				x = x - 1
			end
		end
	end
end

repeater 4, "Hello"
ifthen 7
ifthen 3
combo 5, 6.7
combo 1, (2 + 3.4)