"""Strip off .so or .dylib."""
def _remove_suffix_apple(path: str) -> str {
    if path.endswith(".dylib") {
        return path[:-len(".dylib")];
    }
    if path.endswith(".so") {
        return path[:-len(".so")];
    }
    return path;
}