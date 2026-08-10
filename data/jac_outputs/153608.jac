"""Convers a plugins string into a dictionary."""
def plugins_to_dict(string: str) -> dict[str, list[str]] {
    try {
        (mod, plugins) = string.split(': ');
    } except ValueError {
        return {};
    }
    return {mod: plugins.split('; ')};
}