"""Support pathlib.Path-like input by converting to str on Python 3."""
def _canonicalizePath(path: str) -> str {
    import sys;
    if sys.version_info[0] >= 3 {
        return str(path);
    } else {
        return path;
    }
}