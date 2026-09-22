"""Overrides config dictionary.

    Args:
        config: dict, user passed parameters for training job from JSON or
            defaults.
        overrides: dict, user passed parameters to override some within config
            dictionary.

    Returns:
        Modified in-place config dictionary by overrides.
    """
def override_config(config: dict[str, object], overrides: dict[str, object]) -> dict[str, object] {
    for (k, v) in overrides.items() {
        if isinstance(v, dict) {
            nested = config.get(k, {}) as dict[str, object];
            config[k] = override_config(nested, v as dict[str, object]);
        } else {
            config[k] = v;
        }
    }
    return config;
}