"""Recursive glob"""
def glob_all(folder: str, filt: str) -> list {
    import os;
    import fnmatch;
    matches = [];
    for (`root, dirnames, filenames) in os.walk(folder, followlinks=True) {
        for filename in fnmatch.filter(filenames, filt) {
            matches.append(os.path.join(`root, filename));
        }
    }
    return matches;
}