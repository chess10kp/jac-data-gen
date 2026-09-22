"""
    Assigns a unique natural number to each board state.
    """
def get_id(state: list[list[int]]) -> int {
    cell_id = 0;
    exponent = 8;
    for row in state {
        for column in row {
            if column == 1 {
                cell_id += 2 ** exponent;
            }
            exponent -= 1;
        }
    }
    return cell_id;
}