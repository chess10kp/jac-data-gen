"""Returns relative index for the middle frame in sequence."""
def get_seq_middle(seq_length: int) -> int {
    half_offset = int((seq_length - 1) / 2);
    return seq_length - 1 - half_offset;
}