""" Translates a full path to a handle. """
def path2handle(path: str) -> str {
    return path.split('/')[-1];
}