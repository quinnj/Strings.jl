abstract Encoding
abstract DirectIndexedEncoding <: Encoding

immutable ASCII   <: DirectIndexedEncoding end
immutable Latin1  <: DirectIndexedEncoding end

immutable UTF8    <: Encoding end
immutable UTF16LE <: Encoding end
immutable UTF32LE <: DirectIndexedEncoding end
immutable UCS2LE  <: DirectIndexedEncoding end

immutable UTF16BE <: Encoding end
immutable UTF32BE <: DirectIndexedEncoding end
immutable UCS2BE  <: DirectIndexedEncoding end

if ENDIAN_BOM == 0x01020304
    typealias UTF16   UTF16BE
    typealias UTF32   UTF32BE
    typealias UCS2    UCS2BE
    typealias UTF16OE UTF16LE
    typealias UTF32OE UTF32LE
    typealias UCS2OE  UCS2LE
elseif ENDIAN_BOM == 0x04030201
    typealias UTF16   UTF16LE
    typealias UTF32   UTF32LE
    typealias UCS2    UCS2LE
    typealias UTF16OE UTF16BE
    typealias UTF32OE UTF32BE
    typealias UCS2OE  UCS2BE
else
    error("seriously? what is this machine?")
end

codeunit(::Type{ASCII})   = UInt8
codeunit(::Type{Latin1})  = UInt8
codeunit(::Type{UTF8})    = UInt8
codeunit(::Type{UTF16LE}) = UInt16
codeunit(::Type{UTF32LE}) = UInt32
codeunit(::Type{UCS2LE})  = UInt16
codeunit(::Type{UTF16BE}) = UInt16
codeunit(::Type{UTF32BE}) = UInt32
codeunit(::Type{UCS2BE})  = UInt16

# size of code unit in bytes
Base.sizeof{E<:Encoding}(::Type{E}) = sizeof(codeunit(E))
