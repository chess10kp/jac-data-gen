import from os.path { isfile }

"""Check whether path points to a file."""
def isFile(path: str) -> bool {
    return isfile(path);
}