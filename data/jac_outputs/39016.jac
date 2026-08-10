"""As defined in 3.30"""
def row_major_gamma(idx: list[int], shape: list[int]) -> int {
    assert len(idx) == len(shape);
    if not idx {
        return 0;
    }
    assert idx < shape;
    return idx[-1] + shape[-1] * row_major_gamma(idx[:-1], shape[:-1]);
}