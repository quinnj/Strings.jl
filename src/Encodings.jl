#=
module Encodings

export Encoding
export Binary, ASCII, Latin1, UTF8      # 7/8-bit encodings
export UCS2, UCS2LE, UCS2BE, UCS2OE     # 16-bit encodings (16-bit subset of Unicode)
export UTF16, UTF16LE, UTF16BE, UTF16OE # 16-bit encodings
export UTF32, UTF32LE, UTF32BE, UTF32OE # 32-bit encodings
export BIG_ENDIAN
export native_endian, big_endian, codeunit
=#

abstract Encoding
abstract DirectIndexEncoding <: Encoding

abstract Binary <: DirectIndexEncoding
abstract ASCII  <: DirectIndexEncoding
abstract Latin1 <: DirectIndexEncoding

abstract UTF8   <: Encoding
abstract UTF16  <: Encoding
abstract UTF32  <: DirectIndexEncoding
abstract UCS2   <: DirectIndexEncoding

# Opposite endian encodings of 16-bit and 32-bit encodings
abstract UTF16OE <: UTF16
abstract UTF32OE <: UTF32
abstract UCS2OE  <: UCS2

# This is easier to use (and not get the ordering mixed up) than ENDIAN_BOM
const BIG_ENDIAN = reinterpret(UInt32,UInt8[1:4;])[1] == 0x01020304

if BIG_ENDIAN
    abstract UTF16BE <: UTF16
    abstract UTF32BE <: UTF32
    abstract UCS2BE  <: UCS2
    abstract UTF16LE <: UTF16OE
    abstract UTF32LE <: UTF32OE
    abstract UCS2LE  <: UCS2OE
else
    abstract UTF16LE <: UTF16
    abstract UTF32LE <: UTF32
    abstract UCS2LE  <: UCS2
    abstract UTF16BE <: UTF16OE
    abstract UTF32BE <: UTF32OE
    abstract UCS2BE  <: UCS2OE
end

native_endian{E <: Encoding}(::Type{E}) = true
native_endian{E <: UTF16OE}(::Type{E})  = false
native_endian{E <: UTF32OE}(::Type{E})  = false
native_endian{E <: UCS2OE}(::Type{E})   = false

if BIG_ENDIAN
big_endian{E <: Encoding}(::Type{E}) = native_endian(E)
else
big_endian{E <: Encoding}(::Type{E}) = !native_endian(E)
end

codeunit{E <: ASCII}(::Type{E})  = UInt8
codeunit{E <: Latin1}(::Type{E}) = UInt8
codeunit{E <: UTF8}(::Type{E})   = UInt8
codeunit{E <: UTF16}(::Type{E})  = UInt16
codeunit{E <: UCS2}(::Type{E})   = UInt16
codeunit{E <: UTF32}(::Type{E})  = UInt32

# size of code unit in bytes
Base.sizeof{E <: Encoding}(::Type{E}) = sizeof(codeunit(E))

#end
