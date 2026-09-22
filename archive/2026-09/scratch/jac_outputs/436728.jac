"""Return only first pos and it's content."""
def get_single_pos(chunk_containing_pos: str) -> tuple[str, str] {
    pos_char_end_idx = chunk_containing_pos.find(" ");
    pos = chunk_containing_pos[:pos_char_end_idx];
    pos_content = chunk_containing_pos[(pos_char_end_idx + 1):];
    return (pos, pos_content);
}