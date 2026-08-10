"""Returns a list of tags that must be indexed.

The order of returned tags is from more selective to less selective.
"""
def indexed_tags(tags: list[str] | None) -> list[str] {
    if not tags {
        return [];
    }
    sorted(set(t for t in tags if t.startswith(('buildset:', 'build_address:'))))
}