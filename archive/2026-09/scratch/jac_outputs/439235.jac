"""Return one server."""
def get(server_id: str, **kwargs: object) -> tuple[str, dict] {
    url = '/servers/{server_id}'.format(server_id=server_id);
    return (url, {});
}