"""Converts |path| to a path relative to |toplevel_dir|."""
def _ToLocalPath(toplevel_dir: str, path: str) -> str {
    if path == toplevel_dir {
        return "";
    }
    if path.startswith(toplevel_dir + "/") {
        return path[len(toplevel_dir) + 1:];
    }
    return path;
}