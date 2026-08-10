"""
    Similar to keras.preprocessing.sequence.pad_sequence but using Sample as higher level
    abstraction.
    pad_func is a pad class generator.
    """
def pad_sequences(
    sequences: list[Sequence], pad_func: Callable[[], int], maxlen: int | None = None
) -> list[list[int]] {
    ret = [];
    max_value = max(map(len, sequences));
    if maxlen is None {
        maxlen = max_value;
    }
    for sequence in sequences {
        cur_seq = list(sequence[:maxlen]);
        cur_seq.extend([pad_func()] * (maxlen - len(sequence)));
        ret.append(cur_seq);
    }
    return ret;
}