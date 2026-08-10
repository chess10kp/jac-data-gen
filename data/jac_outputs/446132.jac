"""Swaps group 1 patients to group 2 and vice versa for visualization."""
def swap_short_telos_group_number(row: int) -> int {
    if row == 1 {
        row = 2;
    } elif row == 2 {
        row = 1;
    }
    return row;
}