"""Check if there is at least one optional Models dict key in lowercase keys"""
def has_at_least_one_models_key(lc_keys: list[str]) -> bool {
    model_keys = {
        "paper",
        "code",
        "weights",
        "config",
        "readme",
        "metadata",
        "results",
        "incollection"
    };
    return any(k in model_keys for k in lc_keys);
}