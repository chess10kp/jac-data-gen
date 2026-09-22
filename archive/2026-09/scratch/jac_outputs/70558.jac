"""Return True if the given value looks like a tag.

Currently this is identified via refs/tags/ prefixing."""
def IsRefsTags(value: str) -> bool {
    return value.startswith("refs/tags/");
}