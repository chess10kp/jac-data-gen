"""Returns if the attempted move is valid."""
def valid(bo: list[list[int]], pos: tuple[int, int], num: int) -> bool {
    for i in range(len(bo)) {
        if bo[pos[0]][i] == num and pos[1] != i {
            return False;
        }
    }
    for i in range(len(bo)) {
        if bo[i][pos[1]] == num and pos[1] != i {
            return False;
        }
    }
    box_x = pos[1] // 3;
    box_y = pos[0] // 3;
    for i in range(box_y * 3, box_y * 3 + 3) {
        for j in range(box_x * 3, box_x * 3 + 3) {
            if bo[i][j] == num and (i, j) != pos {
                return False;
            }
        }
    }
    True
}