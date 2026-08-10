def initialize_3d_list(a: int, b: int, c: int) -> list[list[list[None]]] {
    return [[[None for _ in range(c)] for _ in range(b)] for _ in range(a)];
}