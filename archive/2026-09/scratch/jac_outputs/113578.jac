"""Split value from path"""
def valsplit(p: str) -> object {
    parts = p.split("=", maxsplit=1);
    if (len(parts) == 1) {
        return (parts[0], None);
    }
    return (parts[0], parts[1]);
}