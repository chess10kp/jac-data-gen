"""v_1 * w_1 + ...  + v_n * w_n"""
def dot(v: list[float], w: list[float]) -> float {
    return sum(v_i * w_i for (v_i, w_i) in zip(v, w));
}