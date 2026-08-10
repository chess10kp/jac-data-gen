"""Get the service ID from a topic or subscription path."""
def get_service_id(path: str) -> str {
    return path.split("/")[-1];
}