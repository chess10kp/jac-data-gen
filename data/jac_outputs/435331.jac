"""Return width, height, x center, and y center for an anchor (window)."""
def genwhctrs(anchor: list[int]) -> tuple[int, int, float, float] {
    base_w = anchor[2] - anchor[0] + 1;
    base_h = anchor[3] - anchor[1] + 1;
    x_ctr = anchor[0] + 0.5 * (base_w - 1);
    y_ctr = anchor[1] + 0.5 * (base_h - 1);
    return (base_w, base_h, x_ctr, y_ctr);
}