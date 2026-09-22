"""Return the canonical container name (shortest linked name, sans leading slash)."""
def get_canonical_container_name(container: dict[str, list[str]]) -> str {
    return sorted(container['Names'], key=lambda (name: str) { len(name); })[0][1:];
}