"""
    Convert a track (row, col) location to (x, y)

    (x, y) convention

    * (0,0) in bottom left
    * x +ve to the right
    * y +ve up

    (row,col) convention:

    * (0,0) in top left
    * row +ve down
    * col +ve to the right

    Args:
        track (list): List of strings describing the track
        r (int): row coordinate to be converted
        c (int): col coordinate to be converted

    Returns:
        tuple: (x, y)
    """
def rc_to_xy(track: list[str], r: int, c: int) -> tuple[int, int] {
    x = c;
    y = len(track) - 1 - r;
    return (x, y);
}