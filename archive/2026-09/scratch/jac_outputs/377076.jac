"""Removes a trailing slash from the given path, if any."""
def normalize_starting_slash(path_info: str) -> str {
    if not path_info {
        return '/';
    } elif path_info[0] != '/' {
        return '/' + path_info;
    } else {
        return path_info;
    }
}