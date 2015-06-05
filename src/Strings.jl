module Strings

using Compat, Mmap

abstract Encoding
abstract DirectIndexedEncoding <: Encoding

immutable ASCII  <: DirectIndexedEncoding end
immutable Latin1 <: DirectIndexedEncoding end

immutable UTF8    <: Encoding end
immutable UTF16LE <: Encoding end
immutable UTF32LE <: DirectIndexedEncoding end
immutable UCS2LE  <: DirectIndexedEncoding end

immutable UTF16BE <: Encoding end
immutable UTF32BE <: DirectIndexedEncoding end
immutable UCS2BE  <: DirectIndexedEncoding end

if ENDIAN_BOM == 0x01020304
    typealias UTF16 UTF16BE
    typealias UTF32 UTF32BE
    typealias UCS2 UCS2BE
elseif ENDIAN_BOM == 0x04030201
    typealias UTF16 UTF16LE
    typealias UTF32 UTF32LE
    typealias UCS2 UCS2LE
else
    error("seriously? what is this machine?")
end

immutable String{T<:Encoding}
  ptr::Ptr{UInt8}
  len::Int
end

function ==(a::String, b::String)
    na = sizeof(a)
    nb = sizeof(b)
    na != nb && return false
    c = ccall(:memcmp, Int32, (Ptr{UInt8}, Ptr{UInt8}, UInt),
              a.ptr, b.ptr, min(na,nb))
    return c == 0
end

const PAGESIZE = @compat Int(@unix ? ccall(:jl_getpagesize, Clong, ()) : ccall(:jl_getallocationgranularity, Clong, ()))

# this would be handled by native Julia GC, but we'll roll our own for now
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

function storebytes!(s::Ptr{UInt8},n::Int,offset::Int=1)
    ensureroom!(n)
    # unsafe_copy!(dest::Ptr{T}, src::Ptr{T}, N)
    ptr = pointer(POOL.pool[POOL.ind])+UInt(POOL.pos)
    unsafe_copy!(ptr, s+UInt(offset), n)
    return ptr, n
end
function storebytes!{N}(ptrs::NTuple{N,Ptr{UInt8}},lens::NTuple{N,Int})
    @inbounds begin
    n = prod(lens)
    ensureroom!(n)
    # unsafe_copy!(dest::Ptr{T}, src::Ptr{T}, N)
    starting_ptr = pointer(POOL.pool[POOL.ind])+UInt(POOL.pos)
    ptr = starting_ptr
    for i = 1:N
        unsafe_copy!(ptr, ptrs[i], lens[i])
        ptr += lens[i]
    end
    end
    return starting_ptr, n
end
function storebytes!(s::Vector{UInt8},n::Int,offset::Int=1)
    ensureroom!(n)
    # unsafe_copy!(dest::Array, do, src::Array, so, N)
    unsafe_copy!(POOL.pool[POOL.ind],POOL.pos,s,offset,n)
    ptr = pointer(POOL.pool[POOL.ind]) + UInt(POOL.pos) - 1
    POOL.pos += n
    return ptr, n
end
storebytes!(s::Vector{UInt16},n::Int) = storebytes!(reinterpret(UInt8,s),n)
storebytes!(s::Vector{UInt32},n::Int) = storebytes!(reinterpret(UInt8,s),n)
storebytes!(s::Vector{Char},n::Int)   = storebytes!(reinterpret(UInt8,s),n)

include("ascii.jl")

end # module
