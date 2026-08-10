"""Set timeout duration for generating static images."""
def set_view_timeout(config: dict[str, dict[str, int]]) -> int {
    return config["settings"].get("view_timeout", 60);
}