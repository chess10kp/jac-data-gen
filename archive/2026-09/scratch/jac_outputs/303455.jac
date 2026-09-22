"""Find all files or directories that match a pattern"""
def find(pattern: str, path: str, directoriesOnly: bool = False) -> list[str] {
    import os;
    import fnmatch;
    result = [];
    for (dir_root, dirs, files) in os.walk(path) {
        if directoriesOnly {
            for name in dirs {
                if fnmatch.fnmatch(name, pattern) {
                    result.append(os.path.join(dir_root, name));
                }
            }
        } else {
            for name in files {
                if fnmatch.fnmatch(name, pattern) {
                    result.append(os.path.join(dir_root, name));
                }
            }
        }
    }
    return result;
}