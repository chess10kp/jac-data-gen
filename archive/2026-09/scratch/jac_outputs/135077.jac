"""Compute identity of alignment between two sequences."""
def _aln_identity(a: str, b: str) -> float {
    assert len(a) == len(b);
    identical_count = sum(1 for (ca, cb) in zip(a, b) if ca == cb);
    return identical_count / float(len(a));
}