"""Prepare a hex dump of binary data, given in any common form
including [[str]], [[list]], [[bytes]], or [[bytearray]]."""
def _multihex(blob: bytes | str | list[int] | bytearray) -> str {
    return ' '.join(['%02X' % b for b in bytearray(blob)]);
}