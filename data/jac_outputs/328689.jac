"""Split the given sequence into `n_chunks` for worker distribution."""
def split_seq(seq: list[int], n_chunks: int) -> list[list[int]] {
    newseq = [];
    splitsize = 1.0 / n_chunks * len(seq);
    for i in range(n_chunks) {
        newseq.append(
            seq[int(round(i * splitsize)):int(round((i + 1) * splitsize))]
        );
    }
    return newseq;
}