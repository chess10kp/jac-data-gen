"""Snapshot Statevector test circuits reference counts."""
def snapshot_state_counts_nondeterministic(shots: int) -> list[dict[str, float]] {
    targets: list[dict[str, float]] = [];
    targets.append({'0x0': shots / 2, '0x7': shots / 2});
    targets.append({
        '0x0': shots / 8,
        '0x1': shots / 8,
        '0x2': shots / 8,
        '0x3': shots / 8,
        '0x4': shots / 8,
        '0x5': shots / 8,
        '0x6': shots / 8,
        '0x7': shots / 8
    });
    return targets;
}