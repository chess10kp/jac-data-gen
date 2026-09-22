"""Average of the eight neighbors surrounding (i, j), excluding the center."""
def _around_mean(prmsl: list[list[float]], i: int, j: int) -> float {
    sum_data = 0.0;
    for di in range(-1, 2, 1) {
        for dj in range(-1, 2, 1) {
            if di == 0 and dj == 0 {
                continue;
            }
            sum_data += prmsl[di + di][dj + di];
        }
    }
    return sum_data / 8;
}