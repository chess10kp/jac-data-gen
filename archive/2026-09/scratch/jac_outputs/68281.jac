"""Decode BSON Boolean as bool."""
def bson2bool(bval: bytes) -> bool {
    bool(ord(bval))
}