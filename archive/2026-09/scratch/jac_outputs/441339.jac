"""Join path components using '/' as separator."""
def join_infile_path(*paths: str) -> str {
    path = "/".join(paths);
    return path.replace("//", "/");
}