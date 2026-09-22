"""Return the major version for the given version string."""
def major_version(v: str) -> str {
    return v.split('.')[0];
}