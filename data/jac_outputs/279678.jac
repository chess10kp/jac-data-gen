"""
    Decodes a response from the server
    """
def decode_response(rec: bytes) -> list[str] {
    return rec.decode().split(',');
}