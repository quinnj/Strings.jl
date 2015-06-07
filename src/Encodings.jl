module Encodings

export Encoding
export Binary, ASCII, Latin1, UTF8      # 7/8-bit encodings
export UCS2, UCS2LE, UCS2BE, UCS2OE     # 16-bit encodings (16-bit subset of Unicode)
export UTF16, UTF16LE, UTF16BE, UTF16OE # 16-bit encodings
export UTF32, UTF32LE, UTF32BE, UTF32OE # 32-bit encodings

abstract Encoding
abstract DirectIndexedEncoding <: Encoding

immutable Binary  <: DirectIndexedEncoding end
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
    # Somebody must have decided to port Julia to a PDP-11!
    error("seriously? what is this machine?")
end
end
