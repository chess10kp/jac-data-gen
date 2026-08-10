"""
Get the bracket depth of index idx.

Raises ValueError if idx is not inside any bracket.
"""
def get_bracket_depth(
    idx: int,
    left_bracket_indices: list[int],
    right_bracket_indices: list[int]
) -> int {
    depth = -1;
    for (i, left_idx) in enumerate(left_bracket_indices) {
        if idx >= left_idx and idx <= right_bracket_indices[i] {
            depth += 1;
        }
    }
    if depth < 0 {
        raise ValueError("cannot find bracket depth");
    }
    return depth;
}