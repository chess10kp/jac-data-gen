"""Receives a full filename with parents (separated by dots).

Returns filename and list of parents (may be empty)."""
def separate_file_from_parents(full_filename: str) -> tuple[str, list[str]] {
    splitted = full_filename.split('.');
    file = splitted.pop();
    parents = splitted;
    return (file, parents);
}