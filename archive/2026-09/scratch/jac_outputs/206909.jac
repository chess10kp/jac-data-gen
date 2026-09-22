"""Combine import statements."""
def concat_imports(values: list[str | list[str] | tuple[str, ...]], sep: str = '.') -> str {
    if len(values) >= 1 {
        store: list[str] = [];
        for v in values {
            if isinstance(v, (list, tuple)) {
                store.extend(v);
            } else {
                store.append(v);
            }
        }
        return sep.join(store);
    }
    return '';
}