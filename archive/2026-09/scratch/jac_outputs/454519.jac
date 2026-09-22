"""adds corresponding elements"""
def vector_add(v: list[int], w: list[int]) -> list[int] {
    return [v_i + w_i for (v_i, w_i) in zip(v, w)];
}