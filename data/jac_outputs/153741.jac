"""Truncate or pad (with zeros) a GT text field."""
def pad_or_truncate(to_pad: str | bytes, length: int) -> bytes {
    if isinstance(to_pad, str) {
        to_pad = to_pad.encode('latin-1');
    }
    return to_pad.ljust(length, b'\x00')[0:length];
}