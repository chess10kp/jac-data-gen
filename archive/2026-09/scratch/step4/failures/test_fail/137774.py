def mask(bits: int) -> int:
    """
    Generate mask of specified size (sequence of '1')
    """
    return (1 << bits) - 1

assert mask(17) == 0b11111111111111111
assert mask(11) == 2047
assert mask(28) == 268435455
assert mask(21) == 2097151
assert mask(16) == 0xffff
assert mask(8) == 0b11111111
assert mask(8) == 0xff
assert mask(14) == 0b11111111111111
assert mask(64) == mask(64)
assert mask(15) == 0b111111111111111
assert mask(19) == 0b1111111111111111111
assert mask(5) == 0x1f
assert mask(32) == 4294967295
assert mask(18) == 0b111111111111111111
assert mask(128) == 340282366920938463463374607431768211455
assert mask(0) == 0b0
assert mask(19) == 524287
assert mask(22) == 4194303
assert mask(8) == mask(8)
assert mask(7) == 0b1111111
assert mask(13) == 8191
assert mask(6) == 0x3f
assert mask(18) == 262143
assert mask(26) == 67108863
assert mask(7) == 0x7f
assert mask(9) == 0b111111111
assert mask(1) == mask(1)
assert mask(64) == 18446744073709551615
assert mask(17) == 131071
assert mask(15) == 32767
assert mask(10) == 1023
assert mask(4) == 0b1111
assert mask(3) == 7
assert mask(200) == mask(200)
assert mask(1) == 1
assert mask(7) == 127
assert mask(25) == 33554431
assert mask(8) == 255
assert mask(2) == 3
assert mask(24) == 16777215
assert mask(4) == mask(4)
assert mask(6) == 0b111111
assert mask(11) == 0b11111111111
assert mask(20) == 1048575
assert mask(3) == 0b111
assert mask(64) == 0xffffffffffffffff
assert mask(5) == 0b11111
assert mask(64) == (1 << 64) - 1
assert mask(2) == mask(2)
assert mask(31) == mask(31)
assert mask(0) == 0
assert mask(6) == 63
assert mask(2) == 0b11
assert mask(14) == 16383
assert mask(23) == 8388607
assert mask(5) == mask(5)
assert mask(10) == 0b1111111111
assert mask(32) == (1 << 32) - 1
assert mask(5) == 31
assert mask(1) == 0b1
assert mask(32) == mask(32)
assert mask(13) == 0b1111111111111
assert mask(20) == mask(20)
assert mask(12) == 4095
assert mask(27) == 134217727
assert mask(63) == mask(63)
assert mask(9) == mask(9)
assert mask(4) == 0xf
assert mask(4) == 15
assert mask(16) == 65535
assert mask(3) == mask(3)
assert mask(9) == 511
assert mask(30) == 1073741823
assert mask(7) == mask(7)
assert mask(10) == mask(10)
assert mask(6) == mask(6)
assert mask(16) == 0b1111111111111111
assert mask(12) == 0b111111111111
assert mask(32) == 0xffffffff
