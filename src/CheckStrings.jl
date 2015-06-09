# This file is a part of Julia. License is MIT: http://julialang.org/license

## Functions to check validity of UTF-8, UTF-16, and UTF-32 encoded strings,
#  and also to return information necessary to convert to other encodings

module CheckStrings

using Encodings

export check_string
export is_surrogate_lead, is_surrogate_trail, is_surrogate_codeunit, is_valid_continuation

using Base.UTF_ERR_SHORT, Base.UTF_ERR_CONT,Base.UTF_ERR_LONG,
      Base.UTF_ERR_NOT_LEAD, Base.UTF_ERR_NOT_TRAIL,
      Base.UTF_ERR_SURROGATE, Base.UTF_ERR_MISSING_SURROGATE, Base.UTF_ERR_INVALID

is_surrogate_lead(c::Unsigned) = ((c & ~0x003ff) == 0xd800)
is_surrogate_trail(c::Unsigned) = ((c & ~0x003ff) == 0xdc00)
is_surrogate_codeunit(c::Unsigned) = ((c & ~0x007ff) == 0xd800)
is_valid_continuation(c) = ((c & 0xc0) == 0x80)

## Return flags for check_string function

const UTF_LONG = 1              ##< Long encodings are present
const UTF_LATIN1 = 2            ##< characters in range 0x80-0xFF present
const UTF_UNICODE2 = 4          ##< characters in range 0x100-0x7ff present
const UTF_UNICODE3 = 8          ##< characters in range 0x800-0xd7ff, 0xe000-0xffff
const UTF_UNICODE4 = 16         ##< non-BMP characters present
const UTF_SURROGATE = 32        ##< surrogate pairs present

## Get a UTF-8 continuation byte, give error if invalid, return updated character value
@inline function get_continuation(ch::UInt32, byt::UInt8, pos)
    !is_valid_continuation(byt) && throw(UnicodeError(UTF_ERR_CONT, pos, byt))
    (ch << 6) | (byt & 0x3f)
end

CodeUnitType = Union(UInt8, UInt16, UInt32, Char)
CodeUnitC = AbstractArray{Char}
CodeUnit8 = AbstractArray(UInt8}
CodeUnit16 = AbstractArray{UInt16}
CodeUnit32 = AbstractArray{UInt32}
CodeUnit = Union(CodeUnit8, CodeUnit16, CodeUnit32, CodeUnitC, AbstractString)

"
Validates and calculates number of characters in a UTF-8 encoded vector of `UInt8`

### Input Arguments:
* `::Type{Encoding}`
* `dat::CodeUnit` Vector of `UInt8`, `UInt16`, `UInt32` or `Char`

### Optional Input Arguments:
* `endpos` end position (defaults to `endof(dat)`)
* `pos`    start position (defaults to `start(dat)`)

### Keyword Arguments:
* `accept_long_null`  = `true`  # Modified UTF-8 (`\\0` represented as `b\"\\xc0\\x80\"`)
* `accept_surrogates` = `true`  # `CESU-8`
* `accept_long_char`  = `false` # Accept arbitrary long encodings

### Returns:
*   (total characters, flags, 4-byte, 3-byte, 2-byte)

### Throws:
*   `UnicodeError`
"
function check_string{T <: CodeUnit, E <: Union(UTF8, UTF16, UTF32)} (
                      ::Type{E},
                      dat::T,
                      endpos = endof(dat),
                      pos = start(dat)
                      ;
                      accept_long_null  = true,
                      accept_surrogates = true,
                      accept_long_char  = false)
    local byt::UInt8, ch::UInt32, surr::UInt32
    flags::UInt = 0
    totalchar = num2byte = num3byte = num4byte = 0
    @inbounds while pos <= endpos
        ch, pos = next(dat, pos)
        totalchar += 1
        if ch > 0x7f
            if E <: UTF8
                # Check UTF-8 encoding
                if ch < 0xe0
                    # 2-byte UTF-8 sequence (i.e. characters 0x80-0x7ff)
                    (pos > endpos) && throw(UnicodeError(UTF_ERR_SHORT, pos, ch))
                    byt, pos = next(dat, pos)
                    ch = get_continuation(ch & 0x3f, byt, pos)
                    if ch > 0x7f
                        num2byte += 1
                        flags |= (ch > 0xff) ? UTF_UNICODE2 : UTF_LATIN1
                    elseif accept_long_char
                        flags |= UTF_LONG
                    elseif (ch == 0) && accept_long_null
                        flags |= UTF_LONG
                    else
                        throw(UnicodeError(UTF_ERR_LONG, pos, ch))
                    end
                elseif ch < 0xf0
                    # 3-byte UTF-8 sequence (i.e. characters 0x800-0xffff)
                    (pos + 1 > endpos) && throw(UnicodeError(UTF_ERR_SHORT, pos, ch))
                    byt, pos = next(dat, pos)
                    ch = get_continuation(ch & 0x0f, byt, pos)
                    byt, pos = next(dat, pos)
                    ch = get_continuation(ch, byt, pos)
                    # check for surrogate pairs, make sure correct
                    if is_surrogate_codeunit(ch)
                        !is_surrogate_lead(ch) && throw(UnicodeError(UTF_ERR_NOT_LEAD, pos-2, ch))
                        # next character *must* be a trailing surrogate character
                        (pos + 2 > endpos) && throw(UnicodeError(UTF_ERR_MISSING_SURROGATE, pos-2, ch))
                        byt, pos = next(dat, pos)
                        (byt != 0xed) && throw(UnicodeError(UTF_ERR_NOT_TRAIL, pos, byt))
                        byt, pos = next(dat, pos)
                        surr = get_continuation(0x0000d, byt, pos)
                        byt, pos = next(dat, pos)
                        surr = get_continuation(surr, byt, pos)
                        !is_surrogate_trail(surr) && throw(UnicodeError(UTF_ERR_NOT_TRAIL, pos-2, surr))
                        !accept_surrogates && throw(UnicodeError(UTF_ERR_SURROGATE, pos-2, surr))
                        flags |= UTF_SURROGATE
                        num4byte += 1
                    elseif ch > 0x07ff
                        num3byte += 1
                    elseif accept_long_char
                        flags |= UTF_LONG
                        num2byte += 1
                    else
                        throw(UnicodeError(UTF_ERR_LONG, pos-2, ch))
                    end
                elseif ch < 0xf5
                    # 4-byte UTF-8 sequence (i.e. characters > 0xffff)
                    (pos + 2 > endpos) && throw(UnicodeError(UTF_ERR_SHORT, pos, ch))
                    byt, pos = next(dat, pos)
                    ch = get_continuation(ch & 0x07, byt, pos)
                    byt, pos = next(dat, pos)
                    ch = get_continuation(ch, byt, pos)
                    byt, pos = next(dat, pos)
                    ch = get_continuation(ch, byt, pos)
                    if ch > 0x10ffff
                        throw(UnicodeError(UTF_ERR_INVALID, pos-3, ch))
                    elseif ch > 0xffff
                        num4byte += 1
                    elseif is_surrogate_codeunit(ch)
                        throw(UnicodeError(UTF_ERR_SURROGATE, pos-3, ch))
                    elseif accept_long_char
                        # This is an overly long encoded character
                        flags |= UTF_LONG
                        if ch > 0x7ff
                            num3byte += 1
                        elseif ch > 0x7f
                            num2byte += 1
                        end
                    else
                        throw(UnicodeError(UTF_ERR_LONG, pos-2, ch))
                    end
                else
                    throw(UnicodeError(UTF_ERR_INVALID, pos, ch))
                end
            # Handle UTF16 and UTF32 Encodings
            elseif ch < 0x100
                num2byte += 1
                flags |= UTF_LATIN1
            elseif ch < 0x800
                num2byte += 1
                flags |= UTF_UNICODE2
            elseif ch > 0x0ffff
                (ch > 0x10ffff) && throw(UnicodeError(UTF_ERR_INVALID, pos, ch))
                num4byte += 1
            elseif !is_surrogate_codeunit(ch)
                num3byte += 1
            elseif is_surrogate_lead(ch)
                pos > endpos && throw(UnicodeError(UTF_ERR_MISSING_SURROGATE, pos, ch))
                # next character *must* be a trailing surrogate character
                ch, pos = next(dat, pos)
                !is_surrogate_trail(ch) && throw(UnicodeError(UTF_ERR_NOT_TRAIL, pos, ch))
                num4byte += 1
                if E !<: UTF16
                    !accept_surrogates && throw(UnicodeError(UTF_ERR_SURROGATE, pos, ch))
                    flags |= UTF_SURROGATE
                end
            else
                throw(UnicodeError(UTF_ERR_NOT_LEAD, pos, ch))
            end
        end
    end
    num3byte != 0 && (flags |= UTF_UNICODE3)
    num4byte != 0 && (flags |= UTF_UNICODE4)
    return totalchar, flags, num4byte, num3byte, num2byte
end

check_string{T <: CodeUnit8}(dat::T, endpos) = check_string(UTF8, dat, endpos)
check_string{T <: CodeUnit16}(dat::T, endpos) = check_string(UTF16, dat, endpos)
check_string{T <: Union(CodeUnit32, CodeUnitC, AbstractString)}(dat::T, endpos) = check_string(UTF32, dat, endpos)
check_string{T <: CodeUnit8}(dat::T) = check_string(UTF8, dat)
check_string{T <: CodeUnit16}(dat::T) = check_string(UTF16, dat)
check_string{T <: Union(CodeUnit32, CodeUnitC, AbstractString)}(dat::T) = check_string(UTF32, dat)
end
