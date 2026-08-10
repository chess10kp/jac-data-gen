"""
detect if string is binary (https://stackoverflow.com/a/7392391)
"""
def is_binary_string(string_: str | bytes) -> bool {
    if isinstance(string_, str) {
        string_ = bytes(string_, 'utf-8');
    }
    textchars = bytearray({7, 8, 9, 10, 12, 13, 27} | (set(range(32, 256)) - {127}));
    return bool(string_.translate(None, textchars));
}