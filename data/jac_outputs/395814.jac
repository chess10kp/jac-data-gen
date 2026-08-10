"""artifact_version_unsupported message"""
def artifact_version_unsupported(
    artifact_version: int,
    supported_major_version: int
) -> str {
    return (
        "The decisioning artifact version ({}) is not supported. "
        "This library is compatible with this major version: "
        "{}"
    ).format(artifact_version, supported_major_version);
}