module Strings

using Compat, Mmap

# this would be handled by native Julia GC, but we'll roll our own for now
const PAGESIZE = @compat Int(@unix ? ccall(:jl_getpagesize, Clong, ()) : ccall(:jl_getallocationgranularity, Clong, ()))

type StringPool
    pool::Vector{Vector{UInt8}}
    ind::Int
    pos::Int
end

const POOL = StringPool(Any[Mmap.mmap(UInt8,PAGESIZE)],1,1)

function ensureroom!(n::Int)
    if POOL.pos + n < PAGESIZE
        # we have enough room to allocate `n` bytes
        return
    elseif n < PAGESIZE
        # we're hitting a page boundary
        push!(POOL.pool,Mmap.mmap(UInt8,PAGESIZE))
        POOL.ind += 1
        POOL.pos = 1
        return
    elseif n > PAGESIZE
        totalneededbytes = (div(n, PAGESIZE) + 1) * PAGESIZE
        push!(POOL.pool,Mmap.mmap(UInt8,totalneededbytes))
        POOL.ind += 1
        POOL.pos = 1
        return
    end
end

function storebytes!(s::Ptr{UInt8},n::Int,offset::Int=0)
    ensureroom!(n)
    # unsafe_copy!(dest::Ptr{T}, src::Ptr{T}, N)
    ptr = pointer(POOL.pool[POOL.ind])+UInt(POOL.pos)
    unsafe_copy!(ptr, s+UInt(offset), n)
    return ptr, n
end

storebytes!(s::Vector{UInt8},offset::Int=0) = storebytes!(pointer(s), length(s), offset)
storebytes!(s::Vector{UInt16}) = storebytes!(reinterpret(UInt8,s),length(s)*2)
storebytes!(s::Vector{UInt32}) = storebytes!(reinterpret(UInt8,s),length(s)*4)
storebytes!(s::Vector{Char})   = storebytes!(reinterpret(UInt8,s),length(s)*4)

# implementation files
include("encodings.jl")
include("string.jl")
include("ascii.jl")

end # module

macro s_str(s)
    Strings.String(s)
end