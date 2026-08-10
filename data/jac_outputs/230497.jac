"""
    Rotates the list. Positive numbers rotate left. Negative numbers rotate right.
    """
def rotate_list(in_list: list[int], n: int) -> list[int] {
    return in_list[n:] + in_list[:n];
}