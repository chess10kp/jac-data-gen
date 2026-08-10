"""Change a dictionary of kmer counts to a dictinary with kmer counts
    for a smaller value of k.
    """
def downsize_contextD(
    D: dict[str, list[int]],
    general_pattern: str,
    length: int | None
) -> tuple[dict[str, list[int]], str] {
    res: dict[str, list[int]] = {};
    start: int | None = None;
    end: int | None = None;
    for context in D {
        if start is None {
            assert length is not None;
            assert len(context) > length, f'k-mer:{context} cannot be reduced to length {length}';
            radius1 = len(context) // 2;
            radius2 = length // 2;
            start = radius1 - radius2;
            end = (radius1 - radius2) + length;
        }
        counts = D[context];
        context = context[start:end];
        if context not in res {
            res[context] = [0] * len(counts);
        }
        for i in range(len(counts)) {
            res[context][i] += counts[i];
        }
    }
    return (res, general_pattern[start:end]);
}