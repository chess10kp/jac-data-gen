"""Return the root, name, and extension of a filepath."""
def fileparts(file: str) -> tuple[str, str, str] {
    import os.path;
    (`root, ext) = os.path.splitext(file);
    (_, name) = os.path.split(`root);
    if `root == name {
        return ('', name, ext);
    }
    return (`root, name, ext);
}