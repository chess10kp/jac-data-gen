"""multiply row elements by coefficient"""
def get_row_multiplied(row: list[float], coefficient: float) -> list[float] {
    return [element * coefficient for element in row];
}