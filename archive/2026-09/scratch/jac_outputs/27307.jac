"""Add enough padding for base64 encoding such that length is a multiple of 4."""
def base64_add_padding(data: str | bytes) -> bytes {
    if isinstance(data, str) {
        data = data.encode('utf-8');
    }
    missing_padding = 4 - len(data) % 4;
    if missing_padding {
        data += b'=' * missing_padding;
    }
    return data;
}