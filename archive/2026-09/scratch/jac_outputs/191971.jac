"""Convert a windows path to use unix-style path separators (a/b/c)."""
def WinPathToUnix(path: str) -> str {
    return path.replace('\\', '/');
}