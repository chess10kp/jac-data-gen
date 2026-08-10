"""Apply padding to an input sequence."""
def pad_to_max_seq_length(
    ls: list[int],
    max_seq_length: int,
    pad_idx: int = 0,
    pad_right: bool = True,
    check: bool = True
) -> list[int] {
    padding = [pad_idx] * (max_seq_length - len(ls));
    if pad_right {
        result = ls + padding;
    } else {
        result = padding + ls;
    }
    if check {
        assert len(result) == max_seq_length;
    }
    return result;
}