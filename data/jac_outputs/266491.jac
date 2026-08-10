"""
    This function smooths out the contours created by the model
    """
def average_contour(cnt: list[list[int | float]]) -> list[list[int | float]] {
    result = [cnt[0]];
    n = len(cnt);
    for i in range(1, n) {
        px = (cnt[(i - 1) % n][0] + 2 * cnt[i % n][0] + cnt[(i + 1) % n][0]) / 4;
        py = (cnt[(i - 1) % n][1] + 2 * cnt[i % n][1] + cnt[(i + 1) % n][1]) / 4;
        result.append([int(px), int(py)]);
    }
    return result;
}