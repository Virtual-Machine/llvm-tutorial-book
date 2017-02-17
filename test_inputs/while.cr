x = 0
while x < 5
  y = 5
  x = x + 1
  puts x
  if x <= 2
    while y > 0
      y = y - 1
      puts y
    end
    if 2 + 2 == 5
      puts "Won't print"
    else
      puts "Will print"
      while x + y > 1
        puts "Once"
        y = y - 1
      end
    end
  end
end
