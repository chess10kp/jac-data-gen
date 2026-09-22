import from pathlib { Path }

"""Checks for the given file path exists."""
def path_exists(filename: str) -> bool {
    return Path(filename).exists();
}