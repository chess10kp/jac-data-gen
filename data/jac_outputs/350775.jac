"""Format text for CSV."""
def csv_encode(text: str) -> str {
    encode_table = {'"': '""', '\n': '', '\r': ''};
    return '"%s"' % ''.join(encode_table.get(c, c) for c in text);
}