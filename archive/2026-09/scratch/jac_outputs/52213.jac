"""Base URL for the running application."""
def base_url(server: dict[str, int], app: bool) -> str {
    f"http://127.0.0.1:{server['port']}"
}