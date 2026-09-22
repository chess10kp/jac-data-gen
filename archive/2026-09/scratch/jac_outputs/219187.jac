"""Split the message into separate parts based on the boundary."""
def split_message(data: bytes, boundary: bytes) -> list[bytes] {
    message_parts = data.split(b'--' + boundary);
    return [
        p
        for p in message_parts
        if p != b'--' and p != b'--\r\n' and len(p) != 0 and p != b'\r\n'
    ];
}