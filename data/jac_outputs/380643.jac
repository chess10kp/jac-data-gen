glob KERNEL_3_CELLS = [
    (-1, -1),
    (-1, 0),
    (-1, 1),
    (0, 1),
    (1, 1),
    (1, 0),
    (1, -1),
    (0, -1),
    (-1, -1)
];

glob KERNEL_5_CELLS = [
    (-2, -2),
    (-2, -1),
    (-2, 0),
    (-2, 1),
    (-2, 2),
    (-1, 2),
    (0, 2),
    (1, 2),
    (2, 2),
    (2, 1),
    (2, 0),
    (2, -1),
    (2, -2),
    (1, -2),
    (0, -2),
    (-1, -2),
    (-2, -2)
];

"""
    https://airccj.org/CSCP/vol7/csit76809.pdf pg93
    Crossing number methods is a really simple way to detect ridge endings and ridge bifurcations.
    Then the crossing number algorithm will look at 3x3 pixel blocks:

    if middle pixel is black (represents ridge):
    if pixel on boundary are crossed with the ridge once, then it is a possible ridge ending
    if pixel on boundary are crossed with the ridge three times, then it is a ridge bifurcation
    """
def minutiae_at(pixels: list[list[int]], i: int, j: int, kernel_size: int) -> str {
    if pixels[i][j] == 1 {
        cells = KERNEL_3_CELLS if kernel_size == 3 else KERNEL_5_CELLS;
        values = [pixels[i + l][j + k] for (k, l) in cells];
        crossings = 0;
        for k in range(len(values) - 1) {
            crossings += abs(values[k] - values[k + 1]);
        }
        crossings //= 2;
        if crossings == 1 {
            return "ending";
        }
        if crossings == 3 {
            return "bifurcation";
        }
    }
    return "none";
}