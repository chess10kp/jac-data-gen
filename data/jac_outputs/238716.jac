"""Flatten nested dictionary."""
def flatten_dict(d: object, separator: str = '.', prefix: str = '') -> dict[str, object] {
    return {
        (prefix + separator + k) if prefix else k: v for (kk, vv) in d.items()
        for (k, v) in flatten_dict(vv, separator, kk).items()
    }
        if isinstance(d, dict)
        else {prefix: d};
}