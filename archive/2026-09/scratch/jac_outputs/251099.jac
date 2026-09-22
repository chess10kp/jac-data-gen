"""file_names(files, directory, extension) -> paths

Returns the full path of the given File objects.
"""
def file_names(files: list, directory: str, extension: str) -> list[str] {
    return [f.make_path(directory, extension) for f in files];
}