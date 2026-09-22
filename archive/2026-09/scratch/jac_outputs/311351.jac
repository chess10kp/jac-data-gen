glob BYTE_MASK = 0x7F;
glob CONTINUE_MASK = 0x80;

"""Encode a number using LEB128 encoding (Zarith)."""
def forge_nat(value: int) -> bytes {
    if value < 0 {
        raise ValueError('Value cannot be negative.');
    }
    buf = bytearray();
    more = True;
    while more {
        byte = value & BYTE_MASK;
        value >>= 7;
        if value {
            byte |= CONTINUE_MASK;
        } else {
            more = False;
        }
        buf.append(byte);
    }
    return bytes(buf);
}