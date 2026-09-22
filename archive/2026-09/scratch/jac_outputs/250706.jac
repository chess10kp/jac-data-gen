"""Element-wise subtraction of 2 vectors where the second vector is
    subtracted from the first. Return `x1 - x2`.

    Args:
        x1 (list): First vector. 1 or 2 dimensional.
        x2 (list): Second vector. Same dimenions as `x1`.

    Returns:
        list: A element-wise subtracted list. Same dimensions as `x1`.
    """
def sub(x1: list[float] | list[list[float]], x2: list[float] | list[list[float]]) -> list[float] | list[list[float]] {
    assert len(x1) == len(x2);
    if isinstance(x1[0], list) {
        rows_x1 = x1 as list[list[float]];
        rows_x2 = x2 as list[list[float]];
        assert len(rows_x1[0]) == len(rows_x2[0]);
        diff: list[list[float]] = [];
        for (x1_i, x2_i) in zip(rows_x1, rows_x2) {
            diff_i = [(x1_ij - x2_ij) for (x1_ij, x2_ij) in zip(x1_i, x2_i)];
            diff.append(diff_i);
        }
        return diff;
    }
    vec_x1 = x1 as list[float];
    vec_x2 = x2 as list[float];
    return [(x1_i - x2_i) for (x1_i, x2_i) in zip(vec_x1, vec_x2)];
}