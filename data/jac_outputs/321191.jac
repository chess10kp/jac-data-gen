"""Pad sequences to a common length."""
def _pad_sequences(
    sequences: list[list[int] | tuple[int, ...]],
    pad_tok: int,
    max_length: int
) -> tuple[list[list[int]], list[int]] {
    (sequence_padded, sequence_length) = ([], []);
    for seq in sequences {
        seq = list(seq);
        seq_ = seq[:max_length] + ([pad_tok] * max(max_length - len(seq), 0));
        sequence_padded.append(seq_);
        sequence_length.append(min(len(seq), max_length));
    }
    return (sequence_padded, sequence_length);
}