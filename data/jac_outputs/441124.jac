"""Drops keys not present in model_keys; returns dict with matched keys only."""
def keep_matched_keys(dict_to_modify: dict[str, object], model_keys: set[str] | dict[str, object] | list[str]) -> dict[str, object] {
    if isinstance(model_keys, dict) {
        model_keys = set(model_keys.keys());
    }
    return {
        kept_key: dict_to_modify[kept_key]
        for kept_key in model_keys
        if kept_key != 'empty' and dict_to_modify.get(kept_key) is not None
    };
}