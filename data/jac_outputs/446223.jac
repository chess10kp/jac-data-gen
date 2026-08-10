"""Flips control points from u-row order to v-row order."""
def flip_ctrlpts_u(ctrlpts: list[list[float]], size_u: int, size_v: int) -> list[list[float]] {
    new_ctrlpts = [];
    for i in range(size_u) {
        for j in range(size_v) {
            temp = [float(c) for c in ctrlpts[i + j * size_u]];
            new_ctrlpts.append(temp);
        }
    }
    return new_ctrlpts;
}