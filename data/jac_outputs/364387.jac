"""
    Build a complete parameter set by merging all parameters in the provided
    list from left to right.
    """
def merge_params(params: list[dict[str, object]]) -> dict[str, object] {
    assert isinstance(params, list), f"params needs to be a list of dicts, got {type(params)}={params}";
    for p in params {
        assert isinstance(p, dict), f"params needs to be a list of dicts, got an element {type(p)}={p}";
    }
    assert len(params) >= 1, "params must contain at least one dict";
    merged = {};
    for p in params {
        merged.update(p);
    }
    return merged;
}