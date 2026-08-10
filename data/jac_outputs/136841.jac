"""removes useless points from a path and leaves only turn-points"""
def compress_path(path: list[tuple[int, int]]) -> list[tuple[int, int]] {
    new_path = path;
    i = 0;
    while i < len(new_path) - 2 {
        (x1, y1) = new_path[i];
        (x2, y2) = new_path[i + 1];
        (x3, y3) = new_path[i + 2];
        if (x1 == x2 and x2 == x3) or (y1 == y2 and y2 == y3) {
            new_path.pop(i + 1);
        } else {
            i = i + 1;
        }
    }
    return new_path;
}