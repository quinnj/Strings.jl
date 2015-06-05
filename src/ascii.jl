function String(s::ASCIIString)
    ptr, len = storebytes!(s.data,length(s))
    return String{ASCII}(ptr,len)
end

function Base.show(io::IO, x::String{ASCII})
    if x.len == 0
        print(io, Char('"'), Char('"'))
    else
        print(io, Char('"'))
        for i = 1:x.len
            print(io, Char(unsafe_load(x.ptr, i)))
        end
        print(io, Char('"'))
    end
    return
end
Base.endof(x::String{ASCII}) = x.len
Base.length(x::String{ASCII}) = x.len
Base.sizeof(x::String{ASCII}) = x.len

function Base.getindex(x::String{ASCII}, i::Int)
    0 < i < x.len || throw(BoundsError())
    c = unsafe_load(x.ptr,i)
    return ifelse(c < 0x80, Char(c), '\ufffd')
end

# substring
function getindex(s::String{ASCII}, r::UnitRange{Int})
    n = length(r)
    (0 < first(r) <= s.len && last(r) <= s.len) || throw(BoundsError())
    isempty(r) && return String{ASCII}(C_NULL,0)

    if n < div(s.len,4) || n < 16 # < 25% of original string size or really small
        # just make a copy
        ptr, len = storebytes!(s.ptr, n, first(r)-1)
        return String{ASCII}(ptr,len)
    else
        # share data with original string
        return String{ASCII}(s.ptr+UInt(first(r)-1),n)
    end
end

# concatenation
function string(strs::String{ASCII}...)
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
        unsafe_copy!(ptr, strs[i].ptr, strs[i].len)
        ptr += strs[i].len
    end
    end
    return String{ASCII}(starting_ptr,n)
end