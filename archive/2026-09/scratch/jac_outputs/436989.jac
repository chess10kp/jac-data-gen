"""Replace all 'nan' values in a list with 0."""
def remove_nan(values: list[list[float | int | str]]) -> list[list[float | int | str]] {
    for row in values {
        for (j, val) in enumerate(row) {
            if str(val) == 'nan' {
                row[j] = 0;
            }
        }
    }
    return values;
}