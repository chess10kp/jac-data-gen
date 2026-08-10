"""block turn right."""
def turn_right(block_matrix: list[list[int]], debug: bool = False) -> list[list[int]] {
    new_block = [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]];
    for i in range(4) {
        for j in range(4) {
            new_block[3 - j][i] = block_matrix[i][j];
        }
    }
    if debug {
        print(new_block);
    }
    return new_block;
}