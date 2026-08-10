"""
    Args:
        arr: heightmap array
        index_row: row index of location to check adjacent locations for lower or equally low height
        index_col: column index of location to check adjacent locations for lower or equally low height
    Returns:
        True if check location is lower than all adjacent locations, else False
    """
def check_for_lower_adj_height(arr: list[list[int]], index_row: int, index_col: int) -> bool {
    height = arr[index_row][index_col];
    if index_row >= 1 and height >= arr[index_row - 1][index_col] {
        return False;
    }
    if index_row < len(arr) - 1 and height >= arr[index_row + 1][index_col] {
        return False;
    }
    if index_col >= 1 and height >= arr[index_row][index_col - 1] {
        return False;
    }
    if index_col < len(arr[index_row]) - 1 and height >= arr[index_row][index_col + 1] {
        return False;
    }
    return True;
}