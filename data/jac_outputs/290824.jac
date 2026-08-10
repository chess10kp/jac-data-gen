""" returns name of manifest"""
def getManifestName(manifest: dict[str, dict[str, str]]) -> str {
    manifest["manifest"]["name"]
}