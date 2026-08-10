"""Determine if a version is locked."""
def version_is_locked(version: object) -> object {
    return getattr(version, "versionlock", None);
}