"""Decodes a run-length encoded string."""
def decode(to_be_decoded: str) -> str {
    decoded_parts: list[str] = [];
    num_chars: list[str] = [];
    for c in to_be_decoded {
        if c.isdigit() {
            num_chars.append(c);
        } elif len(num_chars) > 0 {
            num_to_print = int(''.join(num_chars));
            decoded_parts.append(c * num_to_print);
            num_chars = [];
        } else {
            decoded_parts.append(c);
        }
    }
    return ''.join(decoded_parts);
}