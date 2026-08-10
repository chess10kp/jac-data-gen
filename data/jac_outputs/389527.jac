"""Removes extension of the given file path."""
def remove_extension(file_path: str) -> str {
    split_path = file_path.split('.');
    new_name = file_path;
    if len(split_path) > 1 {
        new_name = '.'.join(split_path[:-1]);
    }
    return new_name;
}