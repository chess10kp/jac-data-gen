"""Returns the entity from an API response."""
def _get_entity(response: dict[str, str]) -> str {
    path = response['next'].split('?')[0];
    return path.split('/')[3];
}