import from os.path { normpath, normcase }

"""
Returns true if *path* in a subdirectory of *directory*.
Both paths must be absolute.
"""
def is_subdir(path: str, directory: str) -> bool {
    path = normpath(normcase(path));
    directory = normpath(normcase(directory));
    return path.startswith(directory);
}