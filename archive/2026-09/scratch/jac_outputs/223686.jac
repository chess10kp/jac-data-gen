"""Serializes sudoku grids into a string."""
def serialize(grid: list[list[int]] | None) -> str {
    string = "";
    if grid {
        for row in grid {
            for cell in row {
                string += str(cell);
            }
        }
    }
    return string;
}