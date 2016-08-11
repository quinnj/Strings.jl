# lot's of different languages' string operations
# https://en.wikipedia.org/wiki/Comparison_of_programming_languages_(string_functions)
reload("Strings")
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


### Micro performance benchmarks

# String substring
s = "nice pretty string"
@time for i = 1:1000
    t = s[1:10]
end

s = s"nice pretty string"
@time for i = 1:1000
    t = s[1:10]
end

# String concatenation
s = ""
space = " "
@time for i  = 1:1000
    s  = string(s,space)
end

s = s""
space = s" "
@time for i  = 1:1000
    s = Strings.string(s,space)
end

# contains
s = "longer string to search"
sub = "string"
@time for i = 1:1000
    contains(s,sub)
end

s = s"longer string to search"
t = s"string"
@time for i = 1:1000
    Strings.contains(s,t)
end

#TODO
 # Run for each Encoding
 # Massive small string creation benchmarks
 # Large string creation benchmarks 

# String search

# Count substring occurences

# String split

# String join

# Trim/strip/chomp/chop

# lpad/rpad

# String replace

# lowercase / uppercase

# iterate through small/large string code points / graphemes

# repeat strings

# length of string

# validity checking

# startswith / endswith

# memory usage

function hijack(pid)
    name = first(filter(x->x[4]=="0u",map(l->split(l,' ',keep=false),split(readall(`lsof -p $pid`),'\n',keep=false))))[end]
    run(`kill -STOP $pid`)
    fds = ccall(:open,Cint,(Ptr{UInt8},Cint),name, Base.FS.JL_O_RDWR|Base.FS.JL_O_NOCTTY)
    tty = Base.TTY(RawFD(fds); readable=true)
    term = Base.Terminals.TTYTerminal("xterm",tty,tty,tty)
    eval(Base,:(active_repl = Base.REPL.LineEditREPL($term, true)))
    eval(Base,:(have_color = true))
    println(tty)
    Base.banner(tty)
    @async Base.REPL.run_repl(Base.active_repl)
end
