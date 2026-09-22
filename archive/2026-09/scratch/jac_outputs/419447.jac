"""Need i say?"""
def deep_copy[T](to_copy: list[list[T]], rows: int, cols: int) -> list[list[T]] {
    return [[to_copy[i][j] for j in range(cols)] for i in range(rows)];
}