"""
This functions extracts the modified Behaviour Subsequence (BS) sequence list, which is the original sax word
sequence where every consecutive pairs of sax words are equal are fused into the same sax word.
"""
def extract_modified_bs_sequence(sax_sequence: list[str]) -> tuple[list[str], list[int]] {
    bs_sequence = [];
    bs_lengths = [];
    curr_len = 1;
    for i in range(len(sax_sequence)) {
        curr_bs = sax_sequence[i];
        next_bs = sax_sequence[i + 1] if i < len(sax_sequence) - 1 else '';
        if curr_bs == next_bs {
            curr_len = curr_len + 1;
        } else {
            bs_sequence.append(curr_bs);
            bs_lengths.append(curr_len);
            curr_len = 1;
        }
    }
    return (bs_sequence, bs_lengths);
}