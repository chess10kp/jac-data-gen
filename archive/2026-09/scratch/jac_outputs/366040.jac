"""
Convert a version string into a tuple of integers suitable for doing
comparisons on.
"""
def parse_version(version: str) -> tuple[int, ...] {
    tuple(int(x) for x in version.split('.'))
}