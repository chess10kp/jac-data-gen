"""Combine mappings. Doesn't account for nested behavior"""
def _combine(mappings: list[dict[str, object]]) -> dict[str, object] {
    return {k: v for d in mappings for (k, v) in d.items()};
}