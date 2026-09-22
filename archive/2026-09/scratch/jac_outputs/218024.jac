"""Decode raw BAM base quality scores into ASCII values."""
def decode_base_qual(raw_base_qual: bytes, offset: int = 33) -> str {
    return "".join([chr(q + offset) for q in raw_base_qual]);
}