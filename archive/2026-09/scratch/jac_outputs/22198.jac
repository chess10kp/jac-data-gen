"""Reorder with last third, then first third, then middle third."""
def last_third_first_third_mid_third(seq: list[object]) -> list[object] {
    i = len(seq) // 3;
    return seq[-i:] + seq[:i] + seq[i:-i];
}