"""Encodes a proto string into latin1 bytes."""
def encode_proto_bytes(val: str) -> bytes {
    val.encode('latin1')
}