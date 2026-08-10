"""Retrieve resources for a program, pulling from multiple config sources."""
def get_resources(name: str, config: dict[str, dict[str, dict]]) -> dict[str, dict] {
    return config.get("resources", {}).get(name, {});
}