"""Converts the provided identifier into a valid flask endpoint name."""
def flaskify_endpoint(identifier: str) -> str {
    identifier.replace('.', '_')
}