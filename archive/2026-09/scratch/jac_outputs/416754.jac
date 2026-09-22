"""Convert a nonnegative integer to an octet string."""
def integer_to_octet_string_primitive(length: int, integer: int) -> bytes {
    if integer >= 256 ** length {
        raise ValueError(f"{integer} >= 256 ** {length}");
    }
    index = 0;
    digits = [0] * length;
    while integer {
        digits[index] = integer % 256;
        integer //= 256;
        index += 1;
    }
    return bytes(reversed(digits));
}