glob BYTE_MASK = 0xFF;
glob HIGH_BIT = 0x80;

"""Cyclically shift a byte key one bit to the left."""
def circular_shift_key_one_left(key: list[int]) -> list[int] {
    l = len(key);
    return [
        ((key[i] << 1) & BYTE_MASK) | ((key[(i + 1) % l] & HIGH_BIT) >> 7)
        for i in range(0, l)
    ];
}