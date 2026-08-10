"""
Un-pads the given data sequence by stripping trailing null characters and
    recodes it at utf-8.
"""
def un_pad_and_decode(padded: bytes) -> str {
    unpadded = padded.rstrip(b'\x00') as bytes;
    return unpadded.decode("utf-8");
}