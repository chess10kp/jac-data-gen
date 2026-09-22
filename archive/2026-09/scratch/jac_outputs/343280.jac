"""
    Horizontally flips all angles in the `angles` array.
    """
def flipall_angles(angles: list[int]) -> list[int] {
    [360 - a for a in angles]
}