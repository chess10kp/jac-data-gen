"""Decode tuple_'s first and second elements and XOR them."""
def decode(tuple_: tuple[str, str]) -> str {
    first = int(tuple_[0], base=16);
    second = int(tuple_[1], base=16);
    return '{:x}'.format(first ^ second);
}