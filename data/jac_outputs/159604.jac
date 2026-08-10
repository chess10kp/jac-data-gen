"""Given a shorter sequence, expands it to match the padding in mask."""
def pad_seq_with_mask(seq: str, mask: str) -> str {
    seq_iter = iter(seq);
    new_seq = "";
    for m in mask {
        if m == "+" {
            new_seq += next(seq_iter);
        } elif m == "-" {
            new_seq += "-";
        }
    }
    return new_seq;
}