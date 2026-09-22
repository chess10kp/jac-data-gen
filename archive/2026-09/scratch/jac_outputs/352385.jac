"""Constant-width integer serialization."""
def dump_uint(n: int) -> list[int] {
    buffer = [];
    while n {
        buffer.append(n & 255);
        n >>= 8;
    }
    return buffer;
}