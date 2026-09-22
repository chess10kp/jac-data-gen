"""Filter data points against blank targets."""
def filter_blank_targets(rows: list[dict[str, str | float]]) -> list[dict[str, str | float]] {
    filtered = [];
    for row in rows {
        if row['Target'] == 'blank' {
            assert float(row['median']) == -4;
        } else {
            filtered += [row];
        }
    }
    return filtered;
}