"""Return true if the name is private."""
def _is_private(name: str) -> bool {
    return name.startswith('_');
}