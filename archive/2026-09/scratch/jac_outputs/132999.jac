"""Partitions a sequence into output sequences keyed by partfunc(el)."""
def partitionByFunc[T, K](origseq: list[T], partfunc: Callable[[T], K]) -> tuple[dict[K, list[T]], dict[tuple[K, int], int]] {
    allseqs = {};
    indices = {};
    for (i, el) in enumerate(origseq) {
        partout = partfunc(el);
        seq = allseqs.setdefault(partout, []);
        indices[(partout, len(seq))] = i;
        seq.append(el);
    }
    return (allseqs, indices);
}