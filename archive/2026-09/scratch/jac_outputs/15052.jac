"""Expand the prefix into values for checksum computation."""
def _prefix_expand(prefix: str) -> bytearray {
    retval = bytearray((ord(x) & 31) for x in prefix);
    retval.append(0);
    return retval;
}