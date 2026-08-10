"""Unpad a byte sequence with PKCS #7."""
def pkcs7_unpad(bytes_: bytes, len_: int) -> bytes {
    remainder = bytes_[-1];
    pad_len = remainder if remainder != 0 else len_;
    msg = bytes_[:-pad_len];
    pad = bytes_[-pad_len:];
    if remainder >= len_ or any(p != remainder for p in pad) {
        raise ValueError("Invalid padding");
    }
    return msg;
}