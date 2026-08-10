"""Return the element-wise difference x - y."""
def vec_sub(x: list[float], y: list[float]) -> list[float] {
    [(x_i - y_i) for (x_i, y_i) in zip(x, y)]
}