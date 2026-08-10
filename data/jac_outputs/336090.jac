"""Apply a single correction to a list of tokens."""
def _apply_correction(tokens: list[str], correction: tuple[int, int, int, list[str]], offset: int) -> tuple[list[str], int] {
    (start_token_offset, end_token_offset, _, insertion) = correction;
    to_insert = insertion[0].split(" ");
    end_token_offset += len(to_insert) - 1;
    to_insert_filtered = [t for t in to_insert if t != ""];
    head = tokens[:start_token_offset + offset];
    tail = tokens[end_token_offset + offset:];
    new_tokens = head + to_insert_filtered + tail;
    new_offset = len(to_insert_filtered) - (end_token_offset - start_token_offset) + offset;
    return (new_tokens, new_offset);
}