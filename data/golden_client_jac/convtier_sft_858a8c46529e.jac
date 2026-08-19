def _merge(base: dict, patch: dict) -> dict {
    merged = dict(base);
    for (key, value) in patch.items() {
        if key in merged and isinstance(merged[key], dict) and isinstance(value, dict) {
            merged[key] = _merge(merged[key], value);
        } else {
            merged[key] = value;
        }
    }
    return merged;
}

def deep_merge(spec: dict) -> dict {
    return _merge(spec["base"], spec["patch"]);
}

with entry {
    print(deep_merge({'base': {'a': 1, 'n': {'x': 1, 'y': 2}}, 'patch': {'n': {'y': 9}, 'b': 3}}));
}
