#reload("Strings")
using Base.Test
using Encodings

# write your own tests here
s = Strings.String("hey there")
s[1] == 'h'
s[2] == 'e'
s[3] == 'y'

endof(s) == 9
sizeof(s) == 9
length(s) == 9

s[1:3] == Strings.String("hey")
s[2:4] == Strings.String("ey ")

s = Strings.String("a fairly sizable string to test larger string sizes")
s[1:3] == Strings.String("a f")
s[1:20] == Strings.String("a fairly sizable str")

Strings.string(Strings.String("hey"),Strings.String(" "),Strings.String("ho")) == Strings.String("hey ho")


s = ""
@time for i  = 1:1000
    s *= " "
end

s = Strings.String("")
space = Strings.String(" ")
@time for i  = 1:1000
    s = Strings.string(s,space)
end

# This is here, unless check_string actually gets merged in to Base
csmod = CheckStrings # (or Base)
#
# Test invalid sequences
byt = 0x0
    # Continuation byte not after lead
    for byt in 0x80:0xbf
        @test_throws UnicodeError csmod.check_string(UTF8, UInt8[byt])
    end

    # Test lead bytes
    for byt in 0xc0:0xff
        # Single lead byte at end of string
        @test_throws UnicodeError csmod.check_string(UTF8, UInt8[byt])
        # Lead followed by non-continuation character < 0x80
        @test_throws UnicodeError csmod.check_string(UTF8, UInt8[byt,0])
        # Lead followed by non-continuation character > 0xbf
        @test_throws UnicodeError csmod.check_string(UTF8, UInt8[byt,0xc0])
    end

    # Test overlong 2-byte
    for byt in 0x81:0xbf
        @test_throws UnicodeError csmod.check_string(UTF8, UInt8[0xc0,byt])
    end
    for byt in 0x80:0xbf
        @test_throws UnicodeError csmod.check_string(UTF8, UInt8[0xc1,byt])
    end

    # Test overlong 3-byte
    for byt in 0x80:0x9f
        @test_throws UnicodeError csmod.check_string(UTF8, UInt8[0xe0,byt,0x80])
    end

    # Test overlong 4-byte
    for byt in 0x80:0x8f
        @test_throws UnicodeError csmod.check_string(UTF8, UInt8[0xef,byt,0x80,0x80])
    end

    # Test 4-byte > 0x10ffff
    for byt in 0x90:0xbf
        @test_throws UnicodeError csmod.check_string(UTF8, UInt8[0xf4,byt,0x80,0x80])
    end
    for byt in 0xf5:0xf7
        @test_throws UnicodeError csmod.check_string(UTF8, UInt8[byt,0x80,0x80,0x80])
    end

    # Test 5-byte
    for byt in 0xf8:0xfb
        @test_throws UnicodeError csmod.check_string(UTF8, UInt8[byt,0x80,0x80,0x80,0x80])
    end

    # Test 6-byte
    for byt in 0xfc:0xfd
        @test_throws UnicodeError csmod.check_string(UTF8, UInt8[byt,0x80,0x80,0x80,0x80,0x80])
    end

    # Test 7-byte
    @test_throws UnicodeError csmod.check_string(UTF8, UInt8[0xfe,0x80,0x80,0x80,0x80,0x80,0x80])

    # Three and above byte sequences
    for byt in 0xe0:0xef
        # Lead followed by only 1 continuation byte
        @test_throws UnicodeError csmod.check_string(UTF8, UInt8[byt,0x80])
        # Lead ended by non-continuation character < 0x80
        @test_throws UnicodeError csmod.check_string(UTF8, UInt8[byt,0x80,0])
        # Lead ended by non-continuation character > 0xbf
        @test_throws UnicodeError csmod.check_string(UTF8, UInt8[byt,0x80,0xc0])
    end

    # 3-byte encoded surrogate character(s)
    # Single surrogate
    @test_throws UnicodeError csmod.check_string(UTF8, UInt8[0xed,0xa0,0x80])
    # Not followed by surrogate
    @test_throws UnicodeError csmod.check_string(UTF8, UInt8[0xed,0xa0,0x80,0xed,0x80,0x80])
    # Trailing surrogate first
    @test_throws UnicodeError csmod.check_string(UTF8, UInt8[0xed,0xb0,0x80,0xed,0xb0,0x80])
    # Followed by lead surrogate
    @test_throws UnicodeError csmod.check_string(UTF8, UInt8[0xed,0xa0,0x80,0xed,0xa0,0x80])

    # Four byte sequences
    for byt in 0xf0:0xf4
        # Lead followed by only 2 continuation bytes
        @test_throws UnicodeError csmod.check_string(UTF8, UInt8[byt,0x80,0x80])
        # Lead followed by non-continuation character < 0x80
        @test_throws UnicodeError csmod.check_string(UTF8, UInt8[byt,0x80,0x80,0])
        # Lead followed by non-continuation character > 0xbf
        @test_throws UnicodeError csmod.check_string(UTF8, UInt8[byt,0x80,0x80,0xc0])
    end

# Surrogates
@test_throws UnicodeError csmod.check_string(UTF16, UInt16[0xd800])
@test_throws UnicodeError csmod.check_string(UTF16, UInt16[0xdc00])
@test_throws UnicodeError csmod.check_string(UTF16, UInt16[0xdc00,0xd800])

# Surrogates in UTF-32
@test_throws UnicodeError csmod.check_string(UTF32, UInt32[0xd800])
@test_throws UnicodeError csmod.check_string(UTF32, UInt32[0xdc00])
@test_throws UnicodeError csmod.check_string(UTF32, UInt32[0xdc00,0xd800])

# Characters > 0x10ffff
@test_throws UnicodeError csmod.check_string(UTF32, UInt32[0x110000])

