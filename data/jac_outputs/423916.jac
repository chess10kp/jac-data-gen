"""Reference counts for teleport circuits."""
def teleport_counts(shots: int | float, hex_counts: bool = True) -> list[dict[str, float]] {
    targets = [];
    if hex_counts {
        targets.append(
            {
                '0x0': shots / 4,
                '0x1': shots / 4,
                '0x2': shots / 4,
                '0x3': shots / 4
            }
        );
    } else {
        targets.append(
            {
                '0 0 0': shots / 4,
                '0 0 1': shots / 4,
                '0 1 0': shots / 4,
                '0 1 1': shots / 4
            }
        );
    }
    return targets;
}