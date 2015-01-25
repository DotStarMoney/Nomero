dim as byte a, b, o

a = val("&b00100101")
b = val("&b00111000")
o = a - b
print o, bin(o, 8)
sleep

