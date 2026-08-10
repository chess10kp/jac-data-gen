""" Return a path with quotes added if it contains spaces.  path is the
    path.
    """
def quote(path: str) -> str {
    if " " in path {
        path = f'"{path}"';
    }
    return path;
}