"""Removes n characters from the value of a given column for every row."""
def removeNCharsFromCol(data: list[list[str]], n: int, col: int, start: bool) -> list[list[str]] {
    for row in data {
        try {
            row[col] = row[col][n:] if start else row[col][:-n];
        } except IndexError {
            ;
        }
    }
    return data;
}