"""
Collects specific bytes within a bytes object.
"""
def collect_specific_bytes(
    bytes_object: bytes, start_position: int = 0, width: int = 0
) -> dict[str, bytes | int] {
    content = bytes_object[start_position:(start_position + width)];
    return {"content": content, "new_position": start_position + width};
}