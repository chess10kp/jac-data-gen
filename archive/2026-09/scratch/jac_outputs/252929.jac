"""Returns class membership counts; class label is the last column of each row."""
def uniquecounts(rows: list[list[str | int | float]]) -> dict[str | int | float, int] {
    results: dict[str | int | float, int] = {};
    for row in rows {
        label = row[len(row) - 1];
        if label not in results {
            results[label] = 0;
        }
        results[label] += 1;
    }
    return results;
}