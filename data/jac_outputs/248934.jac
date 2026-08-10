"""Convert from 8-bit bytes to 5-bit array of integers."""
def group_32(s: bytes) -> list[int] {
    result: list[int] = [];
    unused_bits = 0;
    current = 0;
    for c in s {
        unused_bits += 8;
        current = (current << 8) + c;
        while unused_bits > 5 {
            unused_bits -= 5;
            result.append(current >> unused_bits);
            mask = (1 << unused_bits) - 1;
            current &= mask;
        }
    }
    result.append(current << (5 - unused_bits));
    return result;
}