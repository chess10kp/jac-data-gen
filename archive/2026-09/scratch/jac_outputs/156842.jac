"""Generate filename for JSON with items removed from original payload."""
def filename_removed_items(removed_keys: list[str], selector: str | None = None) -> str {
    filename = "_".join(removed_keys);
    if selector is None {
        return "broken_without_attribute_" + filename;
    }
    return "broken_without_" + selector + "_attribute_" + filename;
}