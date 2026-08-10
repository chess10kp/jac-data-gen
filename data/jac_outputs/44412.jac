"""Return the version component of a package name."""
def _version(name: str) -> str {
    return name.rpartition("-")[2];
}