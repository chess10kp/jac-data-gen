"""if path is excluded in list of dirs/files"""
def is_excluded(path: str, dirs: list[str]) -> bool {
    for directory in dirs {
        if path.startswith(directory) {
            return True;
        }
    }
    return False;
}