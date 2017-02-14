def example(z Int32) Int32
	if z > 5
		return 0
	else
		return 1
	end
end

def example_2(x Int32, y Int32) Int32
	return x + y * 2
end

puts example 3
puts example 7
puts example_2 3, 4
puts example_2 (example 1), (example 9)
puts example_2 ((example 1) + 1), 2
puts example_2(3, 4)
puts example_2((3 + 1), 4)