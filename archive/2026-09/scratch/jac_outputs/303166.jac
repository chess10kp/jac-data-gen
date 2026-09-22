"""Return a map from keys to values"""
def zipmap(keys: list[str], vals: list[int]) -> dict[str, int] {
    return {k: v for (k, v) in zip(keys, vals)};
}