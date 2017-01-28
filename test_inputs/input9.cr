def add_xy(x Int32, y Int32) Int32
	return x + y
end

def add_xy_and_3(x Int32, y Int32) Int32
	x = x + 3
	return x + y
end

def get_string_len(x String) Int64
	return strlen x
end

puts add_xy 3, add_xy_and_3 2, 1

puts get_string_len("Hi")

hello = "hello "

world = "world"

puts hello + world

puts hello * add_xy 3, add_xy_and_3 2, 1