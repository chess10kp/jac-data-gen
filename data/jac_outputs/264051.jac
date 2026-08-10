"""Create a matrix."""
def CreateMatrix(rows: list[list[object]]) -> tuple[tuple[object, ...], ...] {
    assert len(rows) > 0, "matrix must not be empty";
    rl = len(rows[0]);
    assert rl > 0, "matrix must not be empty";
    for i in range(1, len(rows)) {
        assert rl == len(rows[i]), "all rows must have the same size";
    }
    row_set = [];
    for r in rows {
        row_set.append(tuple(r));
    }
    return tuple(row_set);
}