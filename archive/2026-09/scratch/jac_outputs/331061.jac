"""Converts 8-bit signed data initally read as unsigned data back to its original relative position."""
def signed_to_unsigned_8bit(data: bytes) -> bytearray {
    converted = bytearray();
    for byte in data {
        if byte > 127 {
            signed = byte - 128;
        } else {
            signed = byte + 128;
        }
        converted.append(signed);
    }
    return converted;
}