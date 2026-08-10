"""Return '/a/b/c' -> ('a', '/b/c')."""
def pop_path(path: str) -> tuple[str, str] {
    if path in ("", "/") {
        return ("", "");
    }
    assert path.startswith("/");
    (first, _sep, rest) = path.lstrip("/").partition("/");
    return (first, "/" + rest);
}