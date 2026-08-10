"""Returns manifest schema version for manifest."""
def getManifestSchemaVersion(manifest: dict[str, dict[str, str | int]]) -> str | int {
    manifest["manifest"]["schemaVersion"]
}