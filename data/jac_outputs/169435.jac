"""
    Move a path from one directory to another. Given the directory the path is
    currently in, moves it to be in the second. The path below the given
    directory level remains the same.
    """
def move_path(current_dir: str, new_dir: str, path: str) -> str {
    if current_dir[-1] != '/' {
        current_dir += '/';
    }
    if new_dir[-1] != '/' {
        new_dir += '/';
    }
    return path.replace(current_dir, new_dir, 1);
}