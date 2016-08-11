### Micro performance benchmarks

# Results Data
## String Type | Benchmark | DateTime Run | 
## Julia Version | Strings.jl Version | 
## Time Elapsed | Bytes Allocated | GC Time
# reload("Strings")

results = Dict("String Type"=>ASCIIString[],
               "String Length"=>Int[],
               "Iterations"=>Int[],
               "Benchmark"   =>ASCIIString[],
               "DateTime Run"=>DateTime[],
               "Version"=>ASCIIString[],
               "Time Elapsed"=>Float64[],
               "Bytes Allocated"=>Int64[],
               "GC Time"=>Float64[])

function update!(a,b,c,d,e,f,g,h,i)
    push!(results["String Type"],a)
    push!(results["String Length"],b)
    push!(results["Iterations"],c)
    push!(results["Benchmark"],d)
    push!(results["DateTime Run"],e)
    push!(results["Version"],f)
    push!(results["Time Elapsed"],g)
    push!(results["Bytes Allocated"],h)
    push!(results["GC Time"],i)
    return
end

JULIA = string(VERSION)
dt = now(Dates.UTC)

BASESTRINGTYPES = Dict(ASCIIString=>"ASCIIString",
                       UTF8String=>"UTF8String",
                       UTF16String=>"UTF16String",
                       UTF32String=>"UTF32String")

const SHORTSTRING = "hey"
const MEDIUMSTRING = "nice pretty string"
const LONGERSTRING = "the quick brown fox jumped over the lazy dog" ^ 5
const MASSIVESTRING = LONGERSTRING ^ 100_000;


# Creating a substring from a string
for (T,S) in BASESTRINGTYPES
    s = convert(T,MEDIUMSTRING)
    r = @timed for i = 1:1000000
      t = s[1:10]
    end
    update!(S,length(MEDIUMSTRING),1000000,"s[1:10]",dt,JULIA,r[2],r[3],r[4])
end

for (T,S) in BASESTRINGTYPES
    for (STR,N) in Dict(SHORTSTRING=>10000,
                        MEDIUMSTRING=>10000,
                        LONGERSTRING=>1000,
                        MASSIVESTRING=>10)
        s = convert(T,STR);
        space = convert(T,STR);
        r = @timed for i = 1:N
            b = SubString(s,1,10)
        end
        update!(S,length(STR),N,"\"SubString(s,1,10)\"",dt,JULIA,r[2],r[3],r[4])
    end
end

# String concatenation
for (T,S) in BASESTRINGTYPES
    for (STR,N) in Dict(SHORTSTRING=>1000,
                        MEDIUMSTRING=>1000,
                        LONGERSTRING=>100,
                        MASSIVESTRING=>5)
        s = convert(T,STR);
        t = convert(T,STR);
        r = @timed for i = 1:N
            s = string(s,t)
        end
        update!(S,length(STR),N,"\"string(a,b)\"",dt,JULIA,r[2],r[3],r[4])
    end
end

# contains
for (T,S) in BASESTRINGTYPES
    for (A,B) in Dict(MEDIUMSTRING=>SHORTSTRING,LONGERSTRING=>SHORTSTRING,MASSIVESTRING=>SHORTSTRING)
        s = convert(T,A);
        sub = convert(T,B);
        N = A === MASSIVESTRING ? 5 : 100000
        r = @timed for i = 1:N
            contains(s,sub)
        end
        update!(S,length(A),N,"contains",dt,JULIA,r[2],r[3],r[4])
    end
end

# length
for (T,S) in BASESTRINGTYPES
    for (STR,N) in Dict(SHORTSTRING=>10000,
                        MEDIUMSTRING=>10000,
                        LONGERSTRING=>10000,
                        MASSIVESTRING=>100)
        s = convert(T,STR);
        r = @timed for i = 1:N
            len = length(s)
        end
        update!(S,length(STR),N,"length",dt,JULIA,r[2],r[3],r[4])
    end
end

# String search char
for (T,S) in BASESTRINGTYPES
    for (A,B) in Dict(MEDIUMSTRING=>SHORTSTRING,LONGERSTRING=>SHORTSTRING,MASSIVESTRING=>SHORTSTRING)
        s = convert(T,A);
        sub = convert(T,B);
        N = A === MASSIVESTRING ? 100 : 1000000
        r = @timed for i = 1:N
            ind = search(A,'y')
        end
        update!(S,length(A),N,"\"search(s,c::Char)\"",dt,JULIA,r[2],r[3],r[4])
    end
end

# String search substring
for (T,S) in BASESTRINGTYPES
    for (A,B) in Dict(MEDIUMSTRING=>SHORTSTRING,LONGERSTRING=>SHORTSTRING,MASSIVESTRING=>SHORTSTRING)
        s = convert(T,A);
        sub = convert(T,B);
        N = A === MASSIVESTRING ? 10 : 1000000
        r = @timed for i = 1:N
            ind = search(A,"hey")
        end
        update!(S,length(A),N,"\"search(s,sub::String)\"",dt,JULIA,r[2],r[3],r[4])
    end
end

# String split
for (T,S) in BASESTRINGTYPES
    for (STR,N) in Dict(SHORTSTRING=>1000,
                        MEDIUMSTRING=>100,
                        LONGERSTRING=>100,
                        MASSIVESTRING=>5)
        s = convert(T,STR);
        r = @timed for i = 1:N
            b = split(s,' ')
        end
        update!(S,length(STR),N,"\"split(s,c::Char)\"",dt,JULIA,r[2],r[3],r[4])
    end
end

# String join
for (T,S) in BASESTRINGTYPES
    for (STR,N) in Dict(SHORTSTRING=>1000,
                        MEDIUMSTRING=>100,
                        LONGERSTRING=>10,
                        MASSIVESTRING=>5)
        s = convert(T,STR);
        r = @timed for i = 1:N
            b = join(s,' ')
        end
        update!(S,length(STR),N,"\"join(s,c::Char)\"",dt,JULIA,r[2],r[3],r[4])
    end
end

# String replace
for (T,S) in BASESTRINGTYPES
    for (STR,N) in Dict(SHORTSTRING=>1000,
                        MEDIUMSTRING=>100,
                        LONGERSTRING=>10,
                        MASSIVESTRING=>5)
        s = convert(T,STR);
        r = @timed for i = 1:N
            b = replace(s,' ',',')
        end
        update!(S,length(STR),N,"\"replace(s,a::Char,b::Char)\"",dt,JULIA,r[2],r[3],r[4])
    end
end

for (T,S) in BASESTRINGTYPES
    for (STR,N) in Dict(SHORTSTRING=>1000,
                        MEDIUMSTRING=>100,
                        LONGERSTRING=>10,
                        MASSIVESTRING=>5)
        s = convert(T,STR);
        r = @timed for i = 1:N
            b = replace(s,"hey",',')
        end
        update!(S,length(STR),N,"\"replace(s,a::String,b::Char)\"",dt,JULIA,r[2],r[3],r[4])
    end
end

for (T,S) in BASESTRINGTYPES
    for (STR,N) in Dict(SHORTSTRING=>1000,
                        MEDIUMSTRING=>100,
                        LONGERSTRING=>10,
                        MASSIVESTRING=>5)
        s = convert(T,STR);
        r = @timed for i = 1:N
            b = replace(s,"hey","ho")
        end
        update!(S,length(STR),N,"\"replace(s,a::String,b::String)\"",dt,JULIA,r[2],r[3],r[4])
    end
end

# lowercase / uppercase
for (T,S) in BASESTRINGTYPES
    for (STR,N) in Dict(SHORTSTRING=>100,
                        MEDIUMSTRING=>10,
                        LONGERSTRING=>5,
                        MASSIVESTRING=>2)
        s = convert(T,STR);
        r = @timed for i = 1:N
            b = uppercase(s)
        end
        update!(S,length(STR),N,"uppercase",dt,JULIA,r[2],r[3],r[4])
    end
end

for (T,S) in BASESTRINGTYPES
    for (STR,N) in Dict(SHORTSTRING=>100,
                        MEDIUMSTRING=>10,
                        LONGERSTRING=>5,
                        MASSIVESTRING=>2)
        s = convert(T,STR);
        r = @timed for i = 1:N
            b = lowercase(s)
        end
        update!(S,length(STR),N,"lowercase",dt,JULIA,r[2],r[3],r[4])
    end
end

# iterate through small/large string code points / graphemes
for (T,S) in BASESTRINGTYPES
    for (STR,N) in Dict(SHORTSTRING=>100,
                        MEDIUMSTRING=>5,
                        LONGERSTRING=>3,
                        MASSIVESTRING=>1)
        s = convert(T,STR);
        r = @timed for i = 1:N
            for c in s
                ch = c
            end
        end
        update!(S,length(STR),N,"for c in STR...",dt,JULIA,r[2],r[3],r[4])
    end
end

for (T,S) in BASESTRINGTYPES
    for (STR,N) in Dict(SHORTSTRING=>100,
                        MEDIUMSTRING=>5,
                        LONGERSTRING=>3,
                        MASSIVESTRING=>1)
        s = convert(T,STR);
        r = @timed for i = 1:N
            for c in graphemes(s)
                ch = c
            end
        end
        update!(S,length(STR),N,"for c in graphemes(STR)...",dt,JULIA,r[2],r[3],r[4])
    end
end

# validity checking
for (T,S) in BASESTRINGTYPES
    T in (UTF16String,UTF32String) && continue
    for (STR,N) in Dict(SHORTSTRING=>10000,
                        MEDIUMSTRING=>10000,
                        LONGERSTRING=>1000,
                        MASSIVESTRING=>100)
        s = convert(T,STR);
        r = @timed for i = 1:N
            b = isvalid(ASCIIString,s)
        end
        update!(S,length(STR),N,"isvalid(ASCII)",dt,JULIA,r[2],r[3],r[4])
    end
end

for (T,S) in BASESTRINGTYPES
    T in (UTF16String,UTF32String) && continue
    for (STR,N) in Dict(SHORTSTRING=>10000,
                        MEDIUMSTRING=>10000,
                        LONGERSTRING=>1000,
                        MASSIVESTRING=>100)
        s = convert(T,STR);
        r = @timed for i = 1:N
            b = isvalid(UTF8String,s)
        end
        update!(S,length(STR),N,"isvalid(UTF8String)",dt,JULIA,r[2],r[3],r[4])
    end
end

for (T,S) in BASESTRINGTYPES
    T in (ASCIIString,UTF8String,UTF32String) && continue
    for (STR,N) in Dict(SHORTSTRING=>10000,
                        MEDIUMSTRING=>10000,
                        LONGERSTRING=>1000,
                        MASSIVESTRING=>100)
        s = convert(T,STR);
        r = @timed for i = 1:N
            b = isvalid(UTF16String,s)
        end
        update!(S,length(STR),N,"isvalid(UTF16String)",dt,JULIA,r[2],r[3],r[4])
    end
end

for (T,S) in BASESTRINGTYPES
    T in (ASCIIString,UTF8String,UTF16String) && continue
    for (STR,N) in Dict(SHORTSTRING=>10000,
                        MEDIUMSTRING=>10000,
                        LONGERSTRING=>1000,
                        MASSIVESTRING=>100)
        s = convert(T,STR);
        r = @timed for i = 1:N
            b = isvalid(UTF32String,s)
        end
        update!(S,length(STR),N,"isvalid(UTF32String)",dt,JULIA,r[2],r[3],r[4])
    end
end

# conversion between encodings
for (T,S) in BASESTRINGTYPES
    for (STR,N) in Dict(SHORTSTRING=>10000,
                        MEDIUMSTRING=>1000,
                        LONGERSTRING=>100,
                        MASSIVESTRING=>10)
        s = convert(T,STR);
        r = @timed for i = 1:N
            b = convert(ASCIIString,s)
        end
        update!(S,length(STR),N,"\"convert(ASCIIString,s)\"",dt,JULIA,r[2],r[3],r[4])
    end
end

for (T,S) in BASESTRINGTYPES
    for (STR,N) in Dict(SHORTSTRING=>10000,
                        MEDIUMSTRING=>1000,
                        LONGERSTRING=>100,
                        MASSIVESTRING=>10)
        s = convert(T,STR);
        r = @timed for i = 1:N
            b = convert(UTF8String,s)
        end
        update!(S,length(STR),N,"\"convert(UTF8String,s)\"",dt,JULIA,r[2],r[3],r[4])
    end
end

for (T,S) in BASESTRINGTYPES
    for (STR,N) in Dict(SHORTSTRING=>10000,
                        MEDIUMSTRING=>1000,
                        LONGERSTRING=>100,
                        MASSIVESTRING=>10)
        s = convert(T,STR);
        r = @timed for i = 1:N
            b = convert(UTF16String,s)
        end
        update!(S,length(STR),N,"\"convert(UTF16String,s)\"",dt,JULIA,r[2],r[3],r[4])
    end
end

for (T,S) in BASESTRINGTYPES
    for (STR,N) in Dict(SHORTSTRING=>10000,
                        MEDIUMSTRING=>1000,
                        LONGERSTRING=>100,
                        MASSIVESTRING=>10)
        s = convert(T,STR);
        r = @timed for i = 1:N
            b = convert(UTF32String,s)
        end
        update!(S,length(STR),N,"\"convert(UTF32String,s)\"",dt,JULIA,r[2],r[3],r[4])
    end
end

function Base.writecsv(file,dict)
    open(file,"w") do f
        write(f,join(keys(dict),','),'\n')
        ks = collect(keys(dict))
        M = length(ks)
        for n = 1:length(dict[ks[1]])
            for m = 1:M
                print(f,dict[ks[m]][n],m == M ? '\n' : ',')
            end
        end
    end
end

t = tempname()
println(t)
writecsv(t,results)
reload("Domo")
domo = Domo.connect("domo-media")
# ds = Domo.create!(domo,Domo.CSV.File(t),"Julia String Benchmarks")
ds = Domo.get(domo,"Julia String Benchmarks")
Domo.push!(ds,Domo.CSV.File(t))

# TODO
 # fix relative length of string(a,b)/contains(a,b) benchmarks
 # add more string lengths
 # how to measure GC impact?
 # post for more feedback
