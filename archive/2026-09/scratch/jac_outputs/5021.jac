"""Transforms a dict with unique sequential integer indices into an array"""
def arrayizeDict(g: dict[int, int]) -> list[int | None] {
    max_key = max(g.keys());
    result: list[int | None] = [None for _ in range(max_key)];
    for (k, v) in g.items() {
        result[k - 1] = v;
    }
    return result;
}