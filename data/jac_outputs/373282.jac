"""Pad the given data to a multiple of 16 bytes using PKCS7 padding."""
def append_PKCS7_padding(b: bytes) -> bytes {
    numpads = 16 - len(b) % 16;
    return b + numpads * bytes(chr(numpads), encoding="ascii");
}