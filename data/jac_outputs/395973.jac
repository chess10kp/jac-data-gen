"""Returns path with escaped space and apostrophe."""
def escape_path(path: str) -> str {
    return path.replace("'", "\\'").replace(" ", "\ ");
}