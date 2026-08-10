"""Remove final forward slash from path if present."""
def removeForwardSlash(path: str) -> str {
    if path.endswith('/') {
        path = path[:-1];
    }
    return path;
}