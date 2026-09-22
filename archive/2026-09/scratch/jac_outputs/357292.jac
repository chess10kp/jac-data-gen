"""SnapshotExpectationValue test circuits reference counts."""
def snapshot_expval_counts(shots: int | float) -> list[dict[str, float]] {
    half = shots / 2;
    return [
        {'0x1': half, '0x3': half},
        {'0x0': half, '0x3': half},
        {'0x1': half, '0x2': half},
    ];
}