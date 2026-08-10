"""Filter list of relation tags matching specified prefixes."""
def filter_tags(tags: tuple[str, ...] | list[str], prefixes: tuple[str, ...] | list[str] | None = None) -> tuple[str, ...] | list[str] {
    if prefixes is not None {
        tags = tuple(t for t in tags if any(t.startswith(p) for p in prefixes));
    }
    return tags;
}