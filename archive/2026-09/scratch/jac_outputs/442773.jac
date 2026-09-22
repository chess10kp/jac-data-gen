"""Uniform representation for args which be name or list of names."""
def _as_set(spec: str | list[str] | dict[str, str] | None) -> list[str] | set[str] {
    if spec is None {
        return [];
    }
    if isinstance(spec, str) {
        return [spec];
    }
    try {
        return set((spec as dict[str, str]).values());
    } except AttributeError {
        return set(spec as list[str]);
    }
}