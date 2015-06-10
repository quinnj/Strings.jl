#reload("Strings")
using Base.Test

s = s"hey there"
s[1] == 'h'
s[2] == 'e'
s[3] == 'y'

endof(s) == 9
sizeof(s) == 9
length(s) == 9

s[1:3] == s"hey"
s[2:4] == s"ey "

s = s"a fairly sizable string to test larger string sizes"
s[1:3] == s"a f"
s[1:20] == s"a fairly sizable str"

Strings.string(s"hey",s" ",s"ho") == s"hey ho"

s = ""
@time for i  = 1:1000
    s *= " "
end

s = s"")
space = s" ")
@time for i  = 1:1000
    s = Strings.string(s,space)
end
