reload("Strings")
using Base.Test

# write your own tests here
s = Strings.String("hey there")
s[1] == 'h'
s[2] == 'e'
s[3] == 'y'

endof(s) == 9
sizeof(s) == 9
length(s) == 9

s[1:3] == Strings.String("hey")
s[2:4] == Strings.String("ey ")

s = Strings.String("a fairly sizable string to test larger string sizes")
s[1:3] == Strings.String("a f")
s[1:20] == Strings.String("a fairly sizable str")

Strings.string(Strings.String("hey"),Strings.String(" "),Strings.String("ho")) == Strings.String("hey ho")


s = ""
@time for i  = 1:1000
    s *= " "
end

s = Strings.String("")
space = Strings.String(" ")
@time for i  = 1:1000
    s = Strings.string(s,space)
end