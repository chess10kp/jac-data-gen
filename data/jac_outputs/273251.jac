"""
I2OSP aka RSA's standard ascii decoder. Decodes integer X into
multiple bytes and converts those ASCII codepoints into an ASCII string.
"""
def rsa_ascii_decode(x: int, x_len: int) -> str {
    bytes_out = [];
    if x >= pow(256, x_len) {
        raise ValueError('Number is too large to fit in output string.');
    }
    while x > 0 {
        bytes_out.append(x % 256);
        x //= 256;
    }
    for _ in range(x_len - len(bytes_out)) {
        bytes_out.append(0);
    }
    return ''.join([chr(b) for b in bytes_out[::-1]]);
}