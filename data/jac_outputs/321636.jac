"""Encode text as a zero-padded big-endian bit string."""
def text_to_bits(
    text: str, encoding: str = "utf-8", errors: str = "surrogatepass"
) -> str {
    bits = bin(int.from_bytes(text.encode(encoding, errors), "big"))[2:];
    bits.zfill(8 * ((len(bits) + 7) // 8))
}