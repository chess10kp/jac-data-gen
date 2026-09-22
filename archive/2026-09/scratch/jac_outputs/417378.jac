"""Search the list for empty ID fields and return true/false accordingly."""
def has_blank_ids(idlist: list[str]) -> bool {
    not all(k for k in idlist)
}