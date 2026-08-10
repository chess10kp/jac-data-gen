"""Returns the last segment of the given urn."""
def is_new(urn: str) -> bool {
    return urn.find("$") >= 0;
}