"""Return the XOR of two byte sequences. The length of the result is the length of the shortest."""
def xor(a: bytes, b: bytes) -> bytes {
    bytes((x ^ y) for (x, y) in zip(a, b))
}