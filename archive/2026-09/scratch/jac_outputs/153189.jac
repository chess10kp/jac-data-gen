"""
    distance computes the Manhattan distance between a and b
        where a and b are either tuples (x,y) or dicts {'x':_, 'y':_}
    """
def distance(a: tuple[int, int] | dict[str, int], b: tuple[int, int] | dict[str, int]) -> int {
    if not isinstance(a, tuple) {
        a = (a['x'], a['y']);
    }
    if not isinstance(b, tuple) {
        b = (b['x'], b['y']);
    }
    dx = int(abs(int(a[0]) - int(b[0])));
    dy = int(abs(int(a[1]) - int(b[1])));
    return dx + dy;
}