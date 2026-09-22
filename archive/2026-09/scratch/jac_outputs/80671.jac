"""Find the index of the pair in seq1 and seq2 with maximum sum."""
def _partition_(seq1: list[float], seq2: list[float]) -> int | float {
    _sum_ = _max_ = _pos_ = float("-inf");
    for (pos, ij) in enumerate(zip(seq1, seq2)) {
        _sum_ = sum(ij);
        if _sum_ > _max_ {
            _max_ = _sum_;
            _pos_ = pos;
        }
    }
    return _pos_;
}