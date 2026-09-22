"""Strips and converts bytes to str."""
def clean(value: bytes | str) -> str {
    if isinstance(value, bytes) {
        value = value.decode();
    }
    if isinstance(value, str) {
        value = value.strip();
    }
    return value;
}