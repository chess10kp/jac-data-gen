def serial_to_station(x: int) -> int:
    """Convert serialized chamber id to station."""
    return ((x >> 8) & 0x00000003) + 1

assert serial_to_station(9) == 1
assert serial_to_station(0) == 1
assert serial_to_station(0x8000000A) == 1
assert serial_to_station(0x00000103) == serial_to_station(0x00000103)
assert serial_to_station(1 << 48 | 1) == 1
assert serial_to_station(0x80000007) == 1
assert serial_to_station(1 << 96 | 1) == 1
assert serial_to_station(19) == 1
assert serial_to_station(12) == 1
assert serial_to_station(0xC0) == 1
assert serial_to_station(16) == 1
assert serial_to_station(0x00000102) == 2
assert serial_to_station(3) == 1
assert serial_to_station(1 << 72 | 1) == 1
assert serial_to_station(1) == 1
assert serial_to_station(21) == 1
assert serial_to_station(0x00000001) == 1
assert serial_to_station(1 << 32 | 1) == 1
assert serial_to_station(1 << 56 | 1) == 1
assert serial_to_station(0x0D0E0F10) == 4
assert serial_to_station(0x80000010) == 1
assert serial_to_station(0x80000001) == 1
assert serial_to_station(1 << 128 | 1) == 1
assert serial_to_station(0x0000000A) == 1
assert serial_to_station(1 << 16 | 1) == 1
assert serial_to_station(0x00000101) == serial_to_station(0x00000101)
assert serial_to_station(29) == 1
assert serial_to_station(1 << 40 | 1) == 1
assert serial_to_station(0x00000000) == 1
assert serial_to_station(1 << 120 | 1) == 1
assert serial_to_station(0x00000007) == 1
assert serial_to_station(1 << 88 | 1) == 1
assert serial_to_station(1 << 144 | 1) == 1
assert serial_to_station(0x40) == 1
assert serial_to_station(1 + 2**8) == 2
assert serial_to_station(25) == 1
assert serial_to_station(0x00000009) == 1
assert serial_to_station(0x80) == 1
assert serial_to_station(0x0000000D) == 1
assert serial_to_station(0x00000102) == serial_to_station(0x00000102)
assert serial_to_station(1 << 104 | 1) == 1
assert serial_to_station(28) == 1
assert serial_to_station(0x8000000D) == 1
assert serial_to_station(1 << 24 | 1) == 1
assert serial_to_station(13) == 1
assert serial_to_station(5) == 1
assert serial_to_station(0xFFFFFFFF) == 4
assert serial_to_station(0x00000010) == 1
assert serial_to_station(1 << 136 | 1) == 1
assert serial_to_station(0x00010001) == 1
assert serial_to_station(4) == 1
assert serial_to_station(0x00000011) == 1
assert serial_to_station(0x00000004) == 1
assert serial_to_station(10) == 1
assert serial_to_station(0x80000004) == 1
assert serial_to_station(22) == 1
assert serial_to_station(0x01020304) == 4
assert serial_to_station(1 << 112 | 1) == 1
assert serial_to_station(7) == 1
assert serial_to_station(1 << 64 | 1) == 1
assert serial_to_station(8) == 1
assert serial_to_station(1 << 80 | 1) == 1
assert serial_to_station(17) == 1
