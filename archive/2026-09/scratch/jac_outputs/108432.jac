"""Returns the version string for retrieving a framework version's specific config."""
def _version_for_config(version: str, config: dict[str, object]) -> str {
    if "version_aliases" in config {
        aliases = config["version_aliases"] as dict[str, str];
        if version in aliases {
            return aliases[version];
        }
    }
    return version;
}