typealias CodeUnits Union(UInt8,UInt16,UInt32,Char)

immutable String{E<:Encoding}
  ptr::Ptr{E} # pointer to code units of encoding E
  len::Int    # number of code units
end

String(x::String) = x
String{E<:Encoding}(::Type{E}=UTF8) = String(convert(Ptr{E},C_NULL), 0)

# core access method; unsafe if !(0 < i < s.len)
getcodeunit{E}(s::String{E},i::Integer=1) = unsafe_load(convert(Ptr{codeunit(E)},s.ptr), i)
codeunits(s::String) = s.len
Base.sizeof{E}(s::String{E}) = codeunits(s) * sizeof(E)

# constructors
String{E<:Encoding}(::Type{E}, ptr::Ptr, len::Int) = String(convert(Ptr{E},ptr), len)

# function String{E<:Encoding}(::Type{E}, ptr::Ptr)
#     # look for NUL terminate
# end

function String{E<:Encoding,C<:CodeUnits}(::Type{E}, s::Vector{C})
    # isvalid(E, s) || throw(ArgumentError("vector is not valid $E"))
    ptr, len = storebytes!(s)
    return String{E}(convert(Ptr{E},ptr),div(len,sizeof(E)))
end

# TODO: remove when no longer needed
String(s::ASCIIString) = String(ASCII, s.data)
String(s::UTF8String)  = String(UTF8,  s.data)
String(s::UTF16String) = String(UTF16, s.data)
String(s::UTF32String) = String(UTF32, s.data)

# indexing by code point
# DirectIndexEncoding: code unit == code point
Base.getindex{E<:DirectIndexEncoding}(s::String{E}, i::Integer=1) = (c = getcodeunit(s, i); ifelse(isvalid(E, c), Char(c), '\uffd'))
Base.endof{E<:DirectIndexEncoding}(s::String{E}) = codeunits(s)
Base.length{E<:DirectIndexEncoding}(s::String{E}) = codeunits(s)

# substring
function Base.getindex{E<:DirectIndexEncoding}(s::String{E}, r::UnitRange{Int})
    n = length(r)
    isempty(r) && return empty(E)
    (0 < first(r) <= endof(s) && last(r) <= endof(s)) || throw(BoundsError())

    if n < div(endof(s),4) || n < 16 # < 25% of original string size or really small
        # just make a copy
        ptr, len = storebytes!(convert(Ptr{UInt8},s.ptr), n * sizeof(codeunit(E)), first(r)-1)
        return String(E, ptr, len)
    else
        # share data with original string
        return String(E, s.ptr + UInt(first(r)-1), n)
    end
end

function Base.getindex(s::String,i::Integer=1)
    error("must implement getindex(s::$(typeof(s)), i) --> Char representing the ith code point in s")
end
Base.endof(s::String) = error("must implement endof(s::$(typeof(s))) --> # of code points in s")
function Base.length(s::String)
    i = start(s)
    done(s,i) && return 0
    n = 1
    while true
        c, j = next(s,i)
        done(s,j) && return n
        n += 1
        i = j
    end
end

Base.start(::String) = 1
Base.done(s::String, i::Integer) = i > endof(s)
Base.next(s::String, i::Integer) = (getindex(s, i), i+1)

function =={E}(a::String{E}, b::String{E})
    na = length(a)
    nb = length(b)
    na != nb && return false
    c = ccall(:memcmp, Int32, (Ptr{UInt8}, Ptr{UInt8}, UInt),
              a.ptr, b.ptr, na * sizeof(codeunit(E)))
    return c == 0
end

function Base.show(io::IO, x::String)
    if codeunits(x) == 0
        print(io, '"', '"')
    else
        print(io, '"')
        for c in x
            print(io, c)
        end
        print(io, Char('"'))
    end
    return
end

# concatenation
function Base.string{E}(strs::String{E}...)
    length(strs) == 1 && return strs[1]
    @inbounds begin
    N = length(strs)
    n = 0
    for i = 1:N
        n += strs[i].len
    end
    ensureroom!(n)
    # unsafe_copy!(dest::Ptr{T}, src::Ptr{T}, N)
    starting_ptr = pointer(POOL.pool[POOL.ind])+UInt(POOL.pos)
    ptr = starting_ptr
    for i = 1:N
        unsafe_copy!(ptr, convert(Ptr{UInt8},strs[i].ptr), sizeof(E) * codeunits(strs[i]))
        ptr += codeunits(strs[i])
    end
    end
    return String{E}(starting_ptr,n)
end

# contains
Base.contains(haystack::String, needle::String) = searchindex(haystack,needle,1)!=0
function Base.searchindex(s::String, t::String, i::Integer=1)
    if length(t) == 1
        search(s,t[1],i)
    else
        searchindex(pointer_to_array(convert(Ptr{UInt8},s.ptr), (s.len,)),
                    pointer_to_array(convert(Ptr{UInt8},t.ptr), (t.len,)), i)
    end
end