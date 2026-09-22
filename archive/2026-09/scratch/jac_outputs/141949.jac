"""Legacy version string"""
def _version_str(version: Any) -> object {
    return '' if (version in (None, 1, '1')) else str(version);
}