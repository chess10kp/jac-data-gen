import from os.path { join }

"""Like os.path.join, but never returns '\' chars"""
def fs_join(*args: str) -> str {
    return join(*args).replace('\\', '/');
}