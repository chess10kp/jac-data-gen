"""Return the length of the longest common sequence for all subseq starting at the given indices."""
def max_common_sequence_length(seq: list[str], indices: list[int], cur_size: int) -> int {
    seqlen = len(seq);
    j = cur_size + 1;
    while j < seqlen - indices[-1] {
        firstnt = seq[indices[0] + j];
        if not all(seq[i + j] == firstnt for i in indices[1:]) {
            return j;
        }
        j += 1;
    }
    return j;
}