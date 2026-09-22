"""Normalizes provided path to: /something/something/something"""
def normalize_path(path: str) -> str {
    while path[len(path) - 1] == ' ' or path[len(path) - 1] == '/' {
        path = path[:len(path) - 1];
    }
    return path;
}