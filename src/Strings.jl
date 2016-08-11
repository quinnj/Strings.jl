module Strings

using Compat

# this would be handled by native Julia GC, but we'll roll our own for now
const PAGESIZE = @compat Int(@unix ? ccall(:jl_getpagesize, Clong, ()) : ccall(:jl_getallocationgranularity, Clong, ()))

type MemoryBlock
    ptr::Ptr{UInt8}
    len::Int
    pos::Int
    rc::Int
    function MemoryBlock(n::Integer=PAGESIZE)
        mb = new(Libc.malloc(n), n, 1, 0)
        finalizer(mb,x->free(mb.ptr))
        return mb
    end
end

immutable MemoryPool
    pool::Vector{MemoryBlock}
    space::Vector{UInt16}
end

const POOL = MemoryPool([MemoryBlock()],[PAGESIZE])

# Find room for `n` bytes to store; returns a pointer::Ptr{UInt8} to a chunk of `n` bytes
function findroom!(n::Int)
    # we know we're not going to have existing space for large chunks
    if n < PAGESIZE
        i = 1
        for i = 1:length(POOL.space)
            if POOL.space[i] >= n
                # we found room for `n` bytes
                mb = POOL.pool[i]
                mb.rc += 1 # increase the MemoryBlock's ref count
                pos = mb.pos
                mb.pos += n # increase the current position in the MemoryBlock
                POOL.space[i] -= n # decrease the available space in the MemoryBlock
                return mb.ptr + pos - 1
            end
        end
    end
    # we didn't find `n` bytes available in any existing MemoryBlocks
    # or `n` >= PAGESIZE anyway
    # we need a big chunk of memory
    aligned = div(n, PAGESIZE) * PAGESIZE # need to PAGESIZE align `n`
    mb = MemoryPool(aligned)
    mb.rc += 1
    mb.pos += n
    push!(POOL.pool, mb)
    push!(POOL.space, aligned - n)
    return mb.ptr
end

function storebytes!(s::Ptr{UInt8},n::Int,offset::Int=0)
    ptr = findroom!(n)
    # unsafe_copy!(dest::Ptr{T}, src::Ptr{T}, N)
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
