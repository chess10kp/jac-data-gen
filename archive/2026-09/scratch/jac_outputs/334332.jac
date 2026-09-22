"""Checks if the path argument is a Windows platform path."""
def is_windows_path(path: str) -> bool {
    return '\\' in path or ':' in path or '|' in path;
}