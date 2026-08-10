"""Get path."""
def _get_path(dir_name: str | None) -> str {
    return dir_name + "/" if dir_name else "";
}