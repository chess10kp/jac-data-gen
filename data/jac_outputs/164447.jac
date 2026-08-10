"""Parse a related_content descriptor (ETSI TS 102 323)."""
def parse_related_content_Descriptor(
    data: bytes, i: int, length: int, end: int
) -> dict[str, str] {
    return {"type": "related_content"};
}