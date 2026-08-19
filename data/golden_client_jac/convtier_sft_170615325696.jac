def transpose_grid(m: list[list[int]]) -> list[list[int]] {
    return [[row[i] for row in m] for i in range(len(m[0]))];
}

with entry {
    print(transpose_grid([[1, 2, 3], [4, 5, 6]]));
}
