"""Get resource name with user_id prefix."""
def _get_resource_name(user_id: str, name: str) -> str {
    user_id + name
}