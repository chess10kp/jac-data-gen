"""Sanitize a package name so we can use it in starlark function names."""
def _sanitize_bin_name(name: str) -> str {
    return name.replace("-", "_");
}