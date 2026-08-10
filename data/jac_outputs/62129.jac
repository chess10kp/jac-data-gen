import glob;

"""List file names in the current directory matching a wildcard pattern."""
def listFiles(wildcardstr: str) -> list[str] {
    return glob.glob(wildcardstr);
}