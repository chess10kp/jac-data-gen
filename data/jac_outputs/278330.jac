"""Get subj/obj position sequence."""
def get_positions(start_idx: int, end_idx: int, length: int) -> list[int] {
    return list(range(-start_idx, 0)) + [0] * ((end_idx - start_idx) + 1) + list(range(1, length - end_idx));
}