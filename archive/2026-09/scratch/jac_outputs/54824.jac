"""Return true if name represents a URL."""
def is_url(name: str) -> bool {
    return '://' in name;
}