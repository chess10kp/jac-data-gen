"""
    Returns list of tags from tag list.
    Each tag in the list may be a list of comma separated tags, with empty strings ignored.
    """
def _tags_from_list(tags: list[str] | None) -> list[str] {
    if tags is not None {
        for tag in tags {
            return [t for t in tag.split(",") if t != ""];
        }
    }
    return [];
}