"""merges b into a"""
def _merge(a: dict[str, object], b: dict[str, object], path: list[str] | None = None) -> dict[str, object] {
    if path is None {
        path = [];
    }
    for (key, bv) in b.items() {
        if key in a {
            av = a[key];
            nested_path = path + [key];
            if isinstance(av, dict) and isinstance(bv, dict) {
                _merge(av, bv, nested_path);
                continue;
            }
        }
        a[key] = bv;
    }
    return a;
}