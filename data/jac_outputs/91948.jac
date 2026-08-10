glob WORD_MASK = 0xFFFF;
glob ROTATE_SHIFT = 0x10;
glob ROTATE_MULT = 0x1000;

"""Bit-rotate 0xAB 0xCD into 0xDA 0xBC and bit-invert result"""
def decode_word(byte1: int, byte2: int) -> tuple[int, int] {
    word = (byte1 * 0x100 + byte2) ^ WORD_MASK;
    rotated = word // ROTATE_SHIFT + (word % ROTATE_SHIFT) * ROTATE_MULT;
    return (rotated // 0x100, rotated % 0x100);
}