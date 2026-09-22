"""Return name with first letter uppercased."""
def _upper_first(name: str) -> str {
    if not name {
        return '';
    }
    return name[0].upper() + name[1:];
}