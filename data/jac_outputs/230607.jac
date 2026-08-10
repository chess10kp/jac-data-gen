"""Implements a comparator using the lexicographical ordering of octets as unsigned integers."""
def _bytearray_comparator(a: bytearray, b: bytearray) -> int {
    a_len = len(a);
    b_len = len(b);
    i = 0;
    while i < a_len and i < b_len {
        a_byte = a[i];
        b_byte = b[i];
        if a_byte != b_byte {
            return -1 if a_byte < b_byte else 1;
        }
        i += 1;
    }
    len_diff = a_len - b_len;
    if len_diff < 0 {
        return -1;
    }
    if len_diff > 0 {
        return 1;
    }
    return 0;
}