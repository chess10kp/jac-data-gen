"""Extracts the semantic version number from a version string."""
def _extract_version_number(bazel_version: str) -> str {
    for (i, c) in enumerate(bazel_version) {
        if not c.isdigit() and c != "." {
            return bazel_version[:i];
        }
    }
    return bazel_version;
}