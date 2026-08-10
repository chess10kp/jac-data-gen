glob CONTENT_CHUNK_SIZE = 50;

"""
    Given some raw bytes, return a display string
    Only show the beginning and end of largish (2x CONTENT_CHUNK_SIZE) arrays.
    """
def split_chunk_for_display(raw_bytes: bytes) -> str {
    if len(raw_bytes) > 2 * CONTENT_CHUNK_SIZE {
        return repr(raw_bytes[:CONTENT_CHUNK_SIZE]) + " ... " + repr(raw_bytes[-CONTENT_CHUNK_SIZE:]);
    }
    return repr(raw_bytes);
}